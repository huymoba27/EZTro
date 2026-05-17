<?php
// File này nhận webhook từ PayOS sau khi người dùng thanh toán xong
header("Content-Type: application/json; charset=UTF-8");

require_once dirname(__DIR__, 2) . '/vendor/autoload.php';
include dirname(__DIR__, 2) . '/config/config.php';
include dirname(__DIR__, 2) . '/config/payment_config.php';

use PayOS\PayOS;

$webhookBody = file_get_contents('php://input');
$webhookData = json_decode($webhookBody, true);
$logFile = __DIR__ . '/webhook_log.txt';

// Debug logging
file_put_contents($logFile, date('[Y-m-d H:i:s] ') . "Body: " . $webhookBody . PHP_EOL, FILE_APPEND);

if (!$webhookData) {
    file_put_contents($logFile, date('[Y-m-d H:i:s] ') . "Error: Invalid payload" . PHP_EOL, FILE_APPEND);
    echo json_encode(["error" => "Invalid payload"]);
    exit;
}

// Bỏ qua nếu là request kiểm tra từ PayOS (thường gửi khi nhấn Save Webhook)
if (isset($webhookData['desc']) && $webhookData['desc'] == 'Webhook test') {
    file_put_contents($logFile, date('[Y-m-d H:i:s] ') . "Info: Webhook test received" . PHP_EOL, FILE_APPEND);
    echo json_encode(["success" => true, "message" => "Webhook test successful"]);
    exit;
}

try {
    $payOS = new PayOS(PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY);

    // Xác thực chữ ký từ PayOS
    // Nếu là signature giả lập từ script simulate_payos.php thì bỏ qua verify
    if (isset($webhookData['signature']) && $webhookData['signature'] === 'SIMULATED_SIGNATURE') {
        $verifiedData = $webhookData; // Dùng luôn dữ liệu giả lập
        file_put_contents($logFile, date('[Y-m-d H:i:s] ') . "Info: Simulated Payment Accepted" . PHP_EOL, FILE_APPEND);
    } else {
        $verifiedData = $payOS->verifyPaymentWebhookData($webhookData);
    }

    if ($verifiedData['code'] === '00') {
        // Thanh toán thành công
        $orderCode = $verifiedData['data']['orderCode'] ?? null;

        if ($orderCode) {
            // === XỬ LÝ HÓA ĐƠN (Invoice) ===
            $stmt = $conn->prepare("SELECT id FROM invoices WHERE payos_order_code = ?");
            $stmt->bind_param("s", $orderCode);
            $stmt->execute();
            $result = $stmt->get_result();

            if ($result->num_rows > 0) {
                $invoice = $result->fetch_assoc();
                $invoice_id = $invoice['id'];

                // Cập nhật trạng thái hóa đơn thành 'paid'
                $conn->query("UPDATE invoices SET status = 'paid' WHERE id = $invoice_id");

                include_once dirname(__DIR__, 2) . '/backend_api/notifications/notify_helper.php';

                // Tự động tạo phiếu thu
                $info_sql = "SELECT i.*, r.house_id, t.tenant_name, h.user_id as landlord_id, u.id as user_tenant_id, t.id as tenant_id, r.room_name 
                             FROM invoices i 
                             JOIN rooms r ON i.room_id = r.id 
                             JOIN houses h ON r.house_id = h.id
                    LEFT JOIN contracts c ON i.contract_id = c.id
                    LEFT JOIN tenants t ON c.tenant_id = t.id
                             LEFT JOIN users u ON t.phone = u.phone AND u.role = 'tenant'
                             WHERE i.id = $invoice_id";
                $info_res = $conn->query($info_sql);
                if ($info_res && $info_res->num_rows > 0) {
                    $info = $info_res->fetch_assoc();
                    $house_id    = intval($info['house_id']);
                    $room_id     = intval($info['room_id']);
                    $landlord_id = intval($info['landlord_id']);
                    $tenant_to_notify = $info['user_tenant_id'] ? intval($info['user_tenant_id']) : 0;
                    $amount      = floatval($info['total_amount']);
                    $tenant_name = $info['tenant_name'] ?? 'Khách thuê';
                    $room_name   = $info['room_name'] ?? 'N/A';
                    $month       = $info['billing_month'] ?? date('m');
                    $year        = $info['billing_year'] ?? date('Y');
                    $desc        = "Thu tiền phòng tháng $month/$year (PayOS)";
                    $receipt_date = date('Y-m-d');

                    $receipt_exists = $conn->query("SELECT id FROM receipts WHERE invoice_id = $invoice_id AND receipt_type = 'monthly_bill' LIMIT 1")->fetch_assoc();
                    if (!$receipt_exists) {
                        $r_stmt = $conn->prepare("INSERT INTO receipts (house_id, room_id, invoice_id, tenant_name, amount, receipt_date, receipt_type, description) VALUES (?, ?, ?, ?, ?, ?, 'monthly_bill', ?)");
                        if ($r_stmt) {
                            $r_stmt->bind_param("iiisdss", $house_id, $room_id, $invoice_id, $tenant_name, $amount, $receipt_date, $desc);
                            $r_stmt->execute();
                            $r_stmt->close();
                        }
                    }

                    // Gửi thông báo cho khách thuê
                    if ($tenant_to_notify > 0) {
                        createNotification($conn, $tenant_to_notify, "Thanh toán hóa đơn thành công", "Hóa đơn tháng $month/$year phòng $room_name đã được thanh toán qua PayOS.", "invoice", ["invoice_id" => $invoice_id]);
                    }
                    // Gửi thông báo cho chủ trọ
                    if ($landlord_id > 0) {
                        createNotification($conn, $landlord_id, "Hóa đơn đã được thanh toán", "Khách thuê $tenant_name (Phòng $room_name) đã thanh toán hóa đơn tháng $month/$year qua PayOS.", "invoice", ["invoice_id" => $invoice_id]);
                    }
                }

                file_put_contents($logFile, date('[Y-m-d H:i:s] ') . "Invoice #$invoice_id paid via PayOS" . PHP_EOL, FILE_APPEND);
            }

            // === XỬ LÝ ĐẶT CỌC (Deposit) ===
            $dep_stmt = $conn->prepare("SELECT d.id, d.room_id, d.house_id, d.customer_name, d.deposit_amount, h.user_id as landlord_id, r.room_name 
                                       FROM deposits d
                                       JOIN houses h ON d.house_id = h.id
                                       JOIN rooms r ON d.room_id = r.id
                                       WHERE d.payos_order_code = ? AND d.status = 'waiting_payment'");
            $dep_stmt->bind_param("s", $orderCode);
            $dep_stmt->execute();
            $dep_result = $dep_stmt->get_result();

            if ($dep_result->num_rows > 0) {
                $dep = $dep_result->fetch_assoc();
                $dep_id = $dep['id'];
                $dep_room_id = intval($dep['room_id']);
                $dep_house_id = intval($dep['house_id']);
                $dep_landlord_id = intval($dep['landlord_id']);
                $dep_amount = floatval($dep['deposit_amount']);
                $dep_customer = $dep['customer_name'];
                $dep_room_name = $dep['room_name'] ?? 'N/A';

                // Cập nhật trạng thái deposit → pending (chờ admin xác nhận)
                $conn->query("UPDATE deposits SET status = 'pending' WHERE id = $dep_id");

                // Cập nhật trạng thái phòng → deposited
                $conn->query("UPDATE rooms SET status = 'deposited' WHERE id = $dep_room_id");

                // Tự động tạo phiếu thu cho tiền cọc
                $receipt_desc = "Thu tiền cọc giữ chỗ phòng $dep_room_name (PayOS)";
                $receipt_date = date('Y-m-d');

                $r_stmt2 = $conn->prepare("INSERT INTO receipts (house_id, room_id, tenant_name, amount, receipt_date, receipt_type, description) VALUES (?, ?, ?, ?, ?, 'deposit', ?)");
                if ($r_stmt2) {
                    $r_stmt2->bind_param("iisdss", $dep_house_id, $dep_room_id, $dep_customer, $dep_amount, $receipt_date, $receipt_desc);
                    $r_stmt2->execute();
                    $r_stmt2->close();
                }

                // Gửi thông báo cho chủ trọ
                include_once dirname(__DIR__, 2) . '/backend_api/notifications/notify_helper.php';
                if ($dep_landlord_id > 0) {
                    createNotification($conn, $dep_landlord_id, "Yêu cầu đặt cọc mới", "Khách $dep_customer đã thanh toán cọc phòng $dep_room_name. Vui lòng xác nhận.", "deposit", ["deposit_id" => $dep_id]);
                }

                file_put_contents($logFile, date('[Y-m-d H:i:s] ') . "Deposit #$dep_id paid via PayOS" . PHP_EOL, FILE_APPEND);
            }
            $dep_stmt->close();
        }
    }

    echo json_encode(["success" => true]);

} catch (Exception $e) {
    file_put_contents('webhook_log.txt', date('[Y-m-d H:i:s] ') . "Exception: " . $e->getMessage() . PHP_EOL, FILE_APPEND);
    http_response_code(400);
    echo json_encode(["error" => $e->getMessage()]);
}
?>
