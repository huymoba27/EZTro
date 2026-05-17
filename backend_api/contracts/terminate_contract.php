<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include __DIR__ . '/../../config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

$data = json_decode(file_get_contents("php://input"));

if(!isset($data->contract_id) || !isset($data->user_id)) {
    echo json_encode(["status" => "error", "message" => "Thiếu dữ liệu"]);
    exit;
}

$id = (int)$data->contract_id;
$user_id = (int)$data->user_id;
$auth = qltro_auth_context($conn, $data);
$user_id = $auth["verified"] ? (int)$auth["user_id"] : 0;
$penalty = floatval($data->penalty_amount ?? 0);
$damage = floatval($data->damage_amount ?? 0);
$cleaning = floatval($data->cleaning_fee ?? 0);
$reason = isset($data->reason) ? $conn->real_escape_string($data->reason) : '';

$conn->begin_transaction();

try {
    // 1. Lấy thông tin hợp đồng
    qltro_assert_can_access_contract($conn, $auth, $id);

    $c_res = $conn->query("SELECT * FROM contracts WHERE id = $id");
    if ($c_res->num_rows === 0) throw new Exception("Không tìm thấy hợp đồng");
    $contract = $c_res->fetch_assoc();
    
    if ($contract['status'] !== 'active') {
        throw new Exception("Hợp đồng này không ở trạng thái hoạt động");
    }

    $room_id = $contract['room_id'];
    $tenant_id = $contract['tenant_id'];
    $cur_month = (int)date('n');
    $cur_year = (int)date('Y');

    $final_invoice = $conn->query("SELECT id FROM invoices WHERE contract_id = $id AND billing_month = $cur_month AND billing_year = $cur_year LIMIT 1")->fetch_assoc();
    if (!$final_invoice) {
        throw new Exception("Chưa lập hóa đơn tháng cuối $cur_month/$cur_year. Vui lòng lập hóa đơn trước khi thanh lý.");
    }

    // 2. Cập nhật trạng thái hợp đồng
    $conn->query("UPDATE contracts SET status = 'ended', end_date = CURDATE() WHERE id = $id");

    // 3. Giải phóng phòng
    $conn->query("UPDATE rooms SET status = 'empty', current_tenants = 0 WHERE id = $room_id");

    // 4. Cập nhật tất cả khách thuê trong phòng sang inactive + ghi log
    $active_tenants = $conn->query("SELECT id, tenant_name FROM tenants WHERE room_id = $room_id AND status = 'active'");
    $conn->query("UPDATE tenants SET status = 'inactive' WHERE room_id = $room_id AND status = 'active'");
    if ($active_tenants) {
        while ($t = $active_tenants->fetch_assoc()) {
            $t_id = $t['id'];
            $t_name = $conn->real_escape_string($t['tenant_name']);
            $conn->query("INSERT INTO tenant_logs (tenant_id, user_id, action, old_status, new_status, reason) 
                          VALUES ($t_id, $user_id, 'deactivate', 'active', 'inactive', 'Thanh lý HĐ #$id - $t_name')");
        }
    }

    // 5. Lấy thông tin cần thiết
    $house_res = $conn->query("SELECT house_id FROM rooms WHERE id = $room_id");
    $house_id = $house_res->fetch_assoc()['house_id'] ?? 0;

    $tenant_res = $conn->query("SELECT tenant_name FROM tenants WHERE id = $tenant_id");
    $tenant_name = $tenant_res->fetch_assoc()['tenant_name'] ?? 'Khách thuê';

    $room_res = $conn->query("SELECT room_name FROM rooms WHERE id = $room_id");
    $room_name = $room_res->fetch_assoc()['room_name'] ?? 'N/A';

    // 6. TÍNH TOÁN TÀI CHÍNH
    $deposit = floatval($contract['deposit_amount']);

    // 6a. Tổng nợ hóa đơn chưa thanh toán (Hệ thống yêu cầu phải lập HĐ trước khi vào đây)
    $debt_res = $conn->query("SELECT SUM(total_amount) as total_debt FROM invoices WHERE contract_id = $id AND status = 'pending'");
    $invoice_debt = floatval($debt_res->fetch_assoc()['total_debt'] ?? 0);

    // 7. TÍNH TOÁN TỔNG KHẤU TRỪ
    $total_deductions = $invoice_debt + $penalty + $damage + $cleaning;
    $server_refund = max(0, $deposit - $total_deductions);
    $loss = max(0, $total_deductions - $deposit);
    $amount_offset_by_deposit = min($deposit, $total_deductions);

    // 8. Cập nhật trạng thái hóa đơn dựa trên cọc
    if ($deposit >= $invoice_debt) {
        $conn->query("UPDATE invoices SET status = 'paid' WHERE contract_id = $id AND status = 'pending'");
    } else {
        // Cọc không đủ -> các hóa đơn pending chuyển thành bad_debt (thất thu)
        $conn->query("UPDATE invoices SET status = 'bad_debt' WHERE contract_id = $id AND status = 'pending'");
    }

    // 9. Tạo phiếu thu tất toán (ghi nhận phần cọc đã dùng để trả nợ)
    if ($amount_offset_by_deposit > 0) {
        $settle_desc = "Tất toán HĐ phòng $room_name. Khấu trừ cọc cho: ";
        $parts = [];
        if ($invoice_debt > 0) $parts[] = "Nợ HĐ(" . number_format($invoice_debt) . "đ)";
        if ($penalty > 0) $parts[] = "Phạt(" . number_format($penalty) . "đ)";
        if ($damage > 0) $parts[] = "Hư hại(" . number_format($damage) . "đ)";
        if ($cleaning > 0) $parts[] = "Vệ sinh(" . number_format($cleaning) . "đ)";
        $settle_desc .= implode(", ", $parts);

        $stmt_r = $conn->prepare("INSERT INTO receipts (house_id, room_id, tenant_name, amount, receipt_date, receipt_type, description) VALUES (?, ?, ?, ?, CURDATE(), 'settlement', ?)");
        $stmt_r->bind_param("iisds", $house_id, $room_id, $tenant_name, $amount_offset_by_deposit, $settle_desc);
        $stmt_r->execute();
    }

    // 10. Tạo phiếu chi hoàn cọc (nếu còn dư)
    if ($server_refund > 0) {
        $refund_desc = "Hoàn tiền cọc dư sau khi thanh lý HĐ phòng $room_name. (Lý do: $reason)";
        $stmt_e = $conn->prepare("INSERT INTO expenses (house_id, room_id, receiver_name, amount, expense_date, expense_type, description) VALUES (?, ?, ?, ?, CURDATE(), 'refund', ?)");
        $stmt_e->bind_param("iisds", $house_id, $room_id, $tenant_name, $server_refund, $refund_desc);
        $stmt_e->execute();
    }

    // 11. Ghi Nhật ký hợp đồng
    $log_reason = $reason . ($loss > 0 ? " | Thất thu: " . number_format($loss) . "đ" : "");
    $stmt_log = $conn->prepare("INSERT INTO contract_logs (contract_id, user_id, action, old_status, new_status, reason, refund_amount) VALUES (?, ?, 'terminate', 'active', 'ended', ?, ?)");
    $stmt_log->bind_param("iisd", $id, $user_id, $log_reason, $server_refund);
    $stmt_log->execute();

    $conn->commit();
    echo json_encode([
        "status" => "success", 
        "message" => "Thanh lý hợp đồng thành công",
        "actual_refund" => $server_refund,
        "loss_amount" => $loss
    ]);

} catch (Exception $e) {
    if ($conn) $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
