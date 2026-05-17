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
$receiver_name = isset($_POST['receiver_name']) ? $_POST['receiver_name'] : (isset($_POST['title']) ? $_POST['title'] : '');
$receiver_name = $conn->real_escape_string($receiver_name);

$amount = isset($_POST['amount']) ? (float)$_POST['amount'] : 0;
$desc = isset($_POST['description']) ? $conn->real_escape_string($_POST['description']) : '';
$date = isset($_POST['expense_date']) ? $_POST['expense_date'] : date('Y-m-d');
$type = isset($_POST['expense_type']) ? $conn->real_escape_string($_POST['expense_type']) : 'other';
$method = isset($_POST['payment_method']) ? $conn->real_escape_string($_POST['payment_method']) : 'Tien mat';

try {
    $auth = qltro_auth_context($conn);
    if ($action === 'delete') {
        if ($id <= 0) throw new Exception("Thiếu ID phiếu chi");
        qltro_assert_can_access_table_row($conn, $auth, "expenses", $id, "Bạn không có quyền thao tác với phiếu chi này");
        $expense = $conn->query("SELECT expense_type FROM expenses WHERE id = $id")->fetch_assoc();
        if (!$expense) throw new Exception("Phiếu chi không tồn tại");
        $system_types = ['refund', 'settlement'];
        if (in_array($expense['expense_type'], $system_types, true)) {
            throw new Exception("Không thể xóa phiếu chi hệ thống.");
        }
        $stmt = $conn->prepare("DELETE FROM expenses WHERE id = ?");
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Xóa phiếu chi thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    if ($house_id <= 0 || $receiver_name === '' || $amount <= 0) throw new Exception("Thiếu thông tin phiếu chi");
    qltro_assert_can_access_house($conn, $auth, $house_id);
    if ($room_id) qltro_assert_can_access_room($conn, $auth, $room_id);

    if ($action === 'update') {
        if ($id <= 0) throw new Exception("Thiếu ID phiếu chi");
        qltro_assert_can_access_table_row($conn, $auth, "expenses", $id, "Bạn không có quyền thao tác với phiếu chi này");
        $stmt = $conn->prepare("UPDATE expenses SET receiver_name = ?, amount = ?, description = ?, expense_date = ?, room_id = ?, expense_type = ?, payment_method = ? WHERE id = ?");
        $stmt->bind_param("sdssissi", $receiver_name, $amount, $desc, $date, $room_id, $type, $method, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
        else throw new Exception($stmt->error);
    } else {
        $stmt = $conn->prepare("INSERT INTO expenses (house_id, room_id, receiver_name, amount, description, expense_date, expense_type, payment_method) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("iisdssss", $house_id, $room_id, $receiver_name, $amount, $desc, $date, $type, $method);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Tạo phiếu chi thành công", "id" => $stmt->insert_id]);
        else throw new Exception($stmt->error);
    }
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
