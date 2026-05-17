<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

// Nhận dữ liệu từ Flutter gửi lên (POST)
$invoice_id = intval($_POST['invoice_id']);
$status = $_POST['status']; // 'paid' hoặc 'pending'
$role = $_POST['role'] ?? 'landlord';
$user_id = intval($_POST['user_id'] ?? 0);
$reason = $conn->real_escape_string($_POST['reason'] ?? '');
$auth = qltro_auth_context($conn);
$role = $auth["verified"] ? $auth["role"] : "guest";
$user_id = $auth["verified"] ? (int)$auth["user_id"] : 0;

if ($invoice_id > 0 && !empty($status)) {
    if (!in_array($status, ['paid', 'pending'], true)) {
        echo json_encode(["status" => "error", "message" => "Trạng thái hóa đơn không hợp lệ"]);
        exit;
    }

    qltro_assert_can_access_invoice($conn, $auth, $invoice_id);
    // 1. Kiểm tra quyền và lấy trạng thái cũ
    $current_row = $conn->query("SELECT status FROM invoices WHERE id = $invoice_id")->fetch_assoc();
    $old_status = $current_row ? $current_row['status'] : '';
    if (!$current_row) {
        echo json_encode(["status" => "error", "message" => "Không tìm thấy hóa đơn"]);
        exit;
    }

    if ($role === 'manager' && $status === 'pending') {
        if ($old_status === 'paid') {
            echo json_encode(["status" => "error", "message" => "Quản lý không có quyền chuyển hóa đơn ĐÃ thanh toán về trạng thái CHỜ. Vui lòng liên hệ chủ trọ!"]);
            exit;
        }
    }

    // 2. Cập nhật trạng thái trong bảng invoices
    $sql = "UPDATE invoices SET status = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("si", $status, $invoice_id);

    if ($stmt->execute()) {
        // 3. Ghi Nhật ký (Audit Log)
        $log_sql = "INSERT INTO invoice_logs (invoice_id, user_id, old_status, new_status, reason) VALUES (?, ?, ?, ?, ?)";
        $log_stmt = $conn->prepare($log_sql);
        $log_stmt->bind_param("iisss", $invoice_id, $user_id, $old_status, $status, $reason);
        $log_stmt->execute();
        $log_stmt->close();

        if ($status === 'pending' && $old_status === 'paid') {
            $delete_receipt = $conn->prepare("DELETE FROM receipts WHERE invoice_id = ? AND receipt_type = 'monthly_bill'");
            $delete_receipt->bind_param("i", $invoice_id);
            $delete_receipt->execute();
            $delete_receipt->close();
        }

        if ($status == 'paid' && $old_status !== 'paid') {
            include_once dirname(__DIR__) . '/notifications/notify_helper.php';
            // Tự động tạo phiếu thu
            $info_sql = "SELECT i.*, r.house_id, t.tenant_name as t_name, r.room_name, h.user_id as landlord_id, u.id as user_tenant_id, t.id as tenant_id
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
                $house_id = intval($info['house_id']);
                $room_id = intval($info['room_id']);
                $landlord_id = intval($info['landlord_id']);
                $tenant_to_notify = $info['user_tenant_id'] ? intval($info['user_tenant_id']) : 0; // Chỉ gửi nếu có tài khoản user
                $amount = floatval($info['total_amount']);
                $room_name = $info['room_name'] ?? 'N/A';
                $tenant_name = $info['t_name'] ?? 'Khách thuê';
                $month = $info['billing_month'] ?? date('m');
                $year = $info['billing_year'] ?? date('Y');
                $desc = "Thu tiền phòng $room_name tháng $month/$year";
                $receipt_date = date('Y-m-d');

                // Tạo phiếu thu
                $receipt_exists = $conn->query("SELECT id FROM receipts WHERE invoice_id = $invoice_id AND receipt_type = 'monthly_bill' LIMIT 1")->fetch_assoc();
                if (!$receipt_exists) {
                    $r_stmt = $conn->prepare("INSERT INTO receipts (house_id, room_id, invoice_id, tenant_name, amount, receipt_date, receipt_type, description) VALUES (?, ?, ?, ?, ?, ?, 'monthly_bill', ?)");
                    if ($r_stmt) {
                        $r_stmt->bind_param("iiisdss", $house_id, $room_id, $invoice_id, $tenant_name, $amount, $receipt_date, $desc);
                        @$r_stmt->execute();
                        $r_stmt->close();
                    }
                }

                // Gửi thông báo cho khách thuê
                if ($tenant_to_notify > 0) {
                    createNotification($conn, $tenant_to_notify, "Thanh toán hóa đơn thành công", "Hóa đơn tháng $month/$year phòng $room_name đã được xác nhận thanh toán.", "invoice", ["invoice_id" => $invoice_id]);
                }
                // Gửi thông báo cho chủ trọ
                if ($landlord_id > 0) {
                    createNotification($conn, $landlord_id, "Hóa đơn đã được thanh toán", "Khách thuê $tenant_name (Phòng $room_name) đã thanh toán hóa đơn tháng $month/$year.", "invoice", ["invoice_id" => $invoice_id]);
                }
            }
        }

        if (ob_get_length() !== false) {
            ob_clean();
        }
        echo json_encode([
            "status" => "success",
            "message" => "Cập nhật trạng thái thành công"
        ]);
    } else {
        echo json_encode([
            "status" => "error",
            "message" => "Lỗi cập nhật: " . $conn->error
        ]);
    }
    $stmt->close();
} else {
    echo json_encode([
        "status" => "error",
        "message" => "Dữ liệu không hợp lệ"
    ]);
}

$conn->close();
?>
