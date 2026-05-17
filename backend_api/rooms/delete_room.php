<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Phương thức không hợp lệ"]);
    exit;
}

$room_id = isset($_POST['room_id']) ? (int)$_POST['room_id'] : 0;
if ($room_id <= 0) {
    echo json_encode(["status" => "error", "message" => "ID phòng không hợp lệ"]);
    exit;
}

try {
    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_room($conn, $auth, $room_id);

    $debt_check = $conn->query("SELECT id FROM invoices WHERE room_id = $room_id AND status != 'paid'")->num_rows;
    if ($debt_check > 0) {
        throw new Exception("Không thể xóa! Phòng này vẫn còn $debt_check hóa đơn chưa thanh toán.");
    }

    $room_check = $conn->query("SELECT current_tenants, status FROM rooms WHERE id = $room_id")->fetch_assoc();
    if (!$room_check) throw new Exception("Phòng không tồn tại");

    $active_contracts = $conn->query("SELECT id FROM contracts WHERE room_id = $room_id AND status = 'active' AND deleted_at IS NULL")->num_rows;
    if ((int)$room_check['current_tenants'] > 0 || $room_check['status'] === 'rented' || $active_contracts > 0) {
        throw new Exception("Không thể xóa phòng đang có khách thuê. Vui lòng thanh lý hợp đồng trước.");
    }

    $history_count = 0;
    foreach ([
        "SELECT id FROM contracts WHERE room_id = $room_id LIMIT 1",
        "SELECT id FROM invoices WHERE room_id = $room_id LIMIT 1",
        "SELECT id FROM meter_readings WHERE room_id = $room_id LIMIT 1",
        "SELECT id FROM receipts WHERE room_id = $room_id LIMIT 1",
        "SELECT id FROM expenses WHERE room_id = $room_id LIMIT 1",
        "SELECT id FROM deposits WHERE room_id = $room_id LIMIT 1",
        "SELECT id FROM posts WHERE room_id = $room_id LIMIT 1",
    ] as $sql) {
        $history_count += $conn->query($sql)->num_rows;
    }

    $conn->begin_transaction();

    if ($history_count > 0) {
        $conn->query("UPDATE tenants SET deleted_at = NOW(), status = 'inactive' WHERE room_id = $room_id AND status != 'inactive'");
        $conn->query("UPDATE posts SET status = 'deleted' WHERE room_id = $room_id AND status != 'deleted'");
        $conn->query("UPDATE rooms SET status = 'deleted', current_tenants = 0 WHERE id = $room_id");
        $conn->commit();
        echo json_encode(["status" => "success", "message" => "Phòng đã có lịch sử phát sinh nên đã được ẩn thay vì xóa vật lý"]);
        exit;
    }

    $images = [];
    $res = $conn->query("SELECT image_path FROM room_images WHERE room_id = $room_id");
    while ($row = $res->fetch_assoc()) $images[] = $row['image_path'];

    $conn->query("DELETE FROM room_images WHERE room_id = $room_id");
    if (!$conn->query("DELETE FROM rooms WHERE id = $room_id")) {
        throw new Exception($conn->error);
    }

    $conn->commit();
    foreach ($images as $image_path) {
        $full_path = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/rooms/" . $image_path;
        if (file_exists($full_path)) @unlink($full_path);
    }

    echo json_encode(["status" => "success", "message" => "Đã xóa phòng thành công"]);
} catch (Exception $e) {
    if ($conn) $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
