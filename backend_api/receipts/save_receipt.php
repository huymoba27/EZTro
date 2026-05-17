<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'save';
$id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
$house_id = isset($_POST['house_id']) ? (int)$_POST['house_id'] : 0;
$room_id = isset($_POST['room_id']) && $_POST['room_id'] !== "" ? (int)$_POST['room_id'] : null;

// Support both the current schema field and the older manual-form alias.
$tenant_name = isset($_POST['tenant_name']) ? $_POST['tenant_name'] : (isset($_POST['payer_name']) ? $_POST['payer_name'] : '');
$tenant_name = $conn->real_escape_string($tenant_name);

$amount = isset($_POST['amount']) ? (float)$_POST['amount'] : 0;
$desc = isset($_POST['description']) ? $conn->real_escape_string($_POST['description']) : '';
$date = isset($_POST['receipt_date']) ? $_POST['receipt_date'] : date('Y-m-d');
$type = isset($_POST['receipt_type']) ? $conn->real_escape_string($_POST['receipt_type']) : 'other';
$method = isset($_POST['payment_method']) ? $conn->real_escape_string($_POST['payment_method']) : 'Tien mat';
$invoice_id = isset($_POST['invoice_id']) && $_POST['invoice_id'] !== "" ? (int)$_POST['invoice_id'] : null;

try {
    $auth = qltro_auth_context($conn);
    if ($action === 'delete') {
        if ($id <= 0) throw new Exception("Thiếu ID phiếu thu");
        qltro_assert_can_access_table_row($conn, $auth, "receipts", $id, "Bạn không có quyền thao tác với phiếu thu này");
        $receipt = $conn->query("SELECT receipt_type, invoice_id FROM receipts WHERE id = $id")->fetch_assoc();
        if (!$receipt) throw new Exception("Phiếu thu không tồn tại");
        $system_types = ['monthly_bill', 'settlement', 'deposit'];
        if (in_array($receipt['receipt_type'], $system_types, true) || !empty($receipt['invoice_id'])) {
            throw new Exception("Không thể xóa phiếu thu hệ thống hoặc phiếu thu liên kết hóa đơn.");
        }
        $stmt = $conn->prepare("DELETE FROM receipts WHERE id = ?");
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Xóa phiếu thu thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    if ($house_id <= 0 || $tenant_name === '' || $amount <= 0) throw new Exception("Thiếu thông tin phiếu thu");
    qltro_assert_can_access_house($conn, $auth, $house_id);
    if ($room_id) qltro_assert_can_access_room($conn, $auth, $room_id);
    if ($invoice_id) qltro_assert_can_access_invoice($conn, $auth, $invoice_id);

    if ($action === 'update') {
        if ($id <= 0) throw new Exception("Thiếu ID phiếu thu");
        qltro_assert_can_access_table_row($conn, $auth, "receipts", $id, "Bạn không có quyền thao tác với phiếu thu này");
        $stmt = $conn->prepare("UPDATE receipts SET tenant_name = ?, amount = ?, description = ?, receipt_date = ?, room_id = ?, receipt_type = ?, payment_method = ?, invoice_id = ? WHERE id = ?");
        $stmt->bind_param("sdssissii", $tenant_name, $amount, $desc, $date, $room_id, $type, $method, $invoice_id, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
        else throw new Exception($stmt->error);
    } else {
        $stmt = $conn->prepare("INSERT INTO receipts (house_id, room_id, tenant_name, amount, description, receipt_date, receipt_type, payment_method, invoice_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("iisdssssi", $house_id, $room_id, $tenant_name, $amount, $desc, $date, $type, $method, $invoice_id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Tạo phiếu thu thành công", "id" => $stmt->insert_id]);
        else throw new Exception($stmt->error);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
