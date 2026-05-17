<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

include __DIR__ . '/../../config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

$data = json_decode(file_get_contents("php://input"));

if(!isset($data->deposit_id) || !isset($data->role)) {
    echo json_encode(["status" => "error", "message" => "Thiếu dữ liệu"]);
    exit;
}

$id = (int)$data->deposit_id;
$auth = qltro_auth_context($conn, $data);
$role = $auth["verified"] ? $auth["role"] : "guest";

if ($role !== 'landlord' && $role !== 'admin') {
    echo json_encode(["status" => "error", "message" => "Bạn không có quyền xóa dữ liệu này"]);
    exit;
}
qltro_assert_can_access_table_row($conn, $auth, "deposits", $id, "Bạn không có quyền thao tác với phiếu cọc này");

// Kiểm tra trạng thái trước khi xóa
$check = $conn->query("SELECT status FROM deposits WHERE id = $id")->fetch_assoc();
if (!$check) {
    echo json_encode(["status" => "error", "message" => "Phiếu cọc không tồn tại"]);
    exit;
}

if ($check['status'] !== 'cancelled') {
    echo json_encode(["status" => "error", "message" => "Chỉ có thể xóa phiếu đặt cọc đã ở trạng thái 'Hủy'"]);
    exit;
}

// Xóa phiếu cọc (Lưu ý: Có thể giữ lại logs hoặc xóa luôn tùy nhu cầu, ở đây tôi xóa sạch để dọn rác)
$conn->begin_transaction();
try {
    $conn->query("DELETE FROM deposit_logs WHERE deposit_id = $id");
    $conn->query("DELETE FROM deposits WHERE id = $id");
    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Đã xóa vĩnh viễn phiếu cọc"]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "error", "message" => "Lỗi: " . $e->getMessage()]);
}
?>
