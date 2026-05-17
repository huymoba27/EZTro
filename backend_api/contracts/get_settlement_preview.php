<?php
include dirname(__DIR__, 2) . '/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$contract_id = isset($_GET['contract_id']) ? (int)$_GET['contract_id'] : 0;

if ($contract_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu mã hợp đồng"]);
    exit;
}

try {
    // 1. Lấy thông tin cơ bản hợp đồng & phòng
    $sql = "SELECT c.*, r.room_name, h.house_name, h.id as house_id, t.tenant_name
            FROM contracts c
            JOIN rooms r ON c.room_id = r.id
            JOIN houses h ON r.house_id = h.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE c.id = $contract_id";
    $res = $conn->query($sql);
    if ($res->num_rows === 0) throw new Exception("Không tìm thấy hợp đồng");
    $contract = $res->fetch_assoc();
    $room_id = $contract['room_id'];

    $cur_month = (int)date('n');
    $cur_year = (int)date('Y');

    // 2. Tổng nợ hóa đơn chưa thanh toán (bao gồm các tháng cũ)
    $debt_res = $conn->query("SELECT SUM(total_amount) as total_debt FROM invoices WHERE contract_id = $contract_id AND status = 'pending'");
    $debt_row = $debt_res->fetch_assoc();
    $final_total_debt = floatval($debt_row['total_debt'] ?? 0);

    // 3. Lấy danh sách chi tiết các hóa đơn nợ
    $unpaid_invoices = [];
    $inv_list_sql = "SELECT id, billing_month, billing_year, total_amount, created_at 
                     FROM invoices 
                     WHERE contract_id = $contract_id AND status = 'pending'
                     ORDER BY billing_year DESC, billing_month DESC";
    $list_res = $conn->query($inv_list_sql);
    while($row = $list_res->fetch_assoc()) $unpaid_invoices[] = $row;

    // 4. KIỂM TRA HÓA ĐƠN THÁNG HIỆN TẠI (Bắt buộc)
    $inv_check = $conn->query("SELECT id FROM invoices WHERE contract_id = $contract_id AND billing_month = $cur_month AND billing_year = $cur_year");
    $has_invoice_this_month = ($inv_check && $inv_check->num_rows > 0);

    echo json_encode([
        "status" => "success",
        "data" => [
            "contract_id" => $contract['id'],
            "tenant_name" => $contract['tenant_name'],
            "room_name" => $contract['room_name'],
            "house_name" => $contract['house_name'],
            "deposit_amount" => floatval($contract['deposit_amount']),
            "total_debt" => $final_total_debt,
            "unpaid_invoices" => $unpaid_invoices,
            "suggested_refund" => max(0, floatval($contract['deposit_amount']) - $final_total_debt),
            "current_month" => $cur_month,
            "current_year" => $cur_year,
            "has_invoice_this_month" => $has_invoice_this_month
        ]
    ]);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
