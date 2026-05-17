<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Phương thức không hợp lệ"]);
    exit;
}

$house_id = isset($_POST['house_id']) ? (int)$_POST['house_id'] : 0;
if ($house_id <= 0) {
    echo json_encode(["status" => "error", "message" => "ID nhà không hợp lệ"]);
    exit;
}

try {
    $auth = qltro_auth_context($conn);
    qltro_assert_can_manage_house_profile($conn, $auth, $house_id);

    $house = $conn->query("SELECT image FROM houses WHERE id = $house_id")->fetch_assoc();
    if (!$house) throw new Exception("Nhà không tồn tại");

    $debt_check = $conn->query("SELECT i.id FROM invoices i JOIN rooms r ON i.room_id = r.id WHERE r.house_id = $house_id AND i.status != 'paid'")->num_rows;
    if ($debt_check > 0) {
        throw new Exception("Không thể xóa nhà! Vẫn còn $debt_check hóa đơn chưa thanh toán.");
    }

    $active_contracts = $conn->query("SELECT c.id FROM contracts c JOIN rooms r ON c.room_id = r.id WHERE r.house_id = $house_id AND c.status = 'active' AND c.deleted_at IS NULL")->num_rows;
    $active_tenants = $conn->query("SELECT t.id FROM tenants t JOIN rooms r ON t.room_id = r.id WHERE r.house_id = $house_id AND t.status = 'active' AND t.deleted_at IS NULL")->num_rows;
    if ($active_contracts > 0 || $active_tenants > 0) {
        throw new Exception("Không thể xóa nhà đang có hợp đồng hoặc khách thuê hoạt động.");
    }

    $history_count = 0;
    foreach ([
        "SELECT id FROM rooms WHERE house_id = $house_id LIMIT 1",
        "SELECT i.id FROM invoices i JOIN rooms r ON i.room_id = r.id WHERE r.house_id = $house_id LIMIT 1",
        "SELECT m.id FROM meter_readings m JOIN rooms r ON m.room_id = r.id WHERE r.house_id = $house_id LIMIT 1",
        "SELECT id FROM receipts WHERE house_id = $house_id LIMIT 1",
        "SELECT id FROM expenses WHERE house_id = $house_id LIMIT 1",
        "SELECT id FROM services WHERE house_id = $house_id LIMIT 1",
        "SELECT id FROM deposits WHERE house_id = $house_id LIMIT 1",
    ] as $sql) {
        $history_count += $conn->query($sql)->num_rows;
    }

    $conn->begin_transaction();

    if ($history_count > 0) {
        $conn->query("UPDATE houses SET status = 'inactive' WHERE id = $house_id");
        $conn->query("UPDATE rooms SET status = 'deleted', current_tenants = 0 WHERE house_id = $house_id AND status NOT IN ('deleted')");
        $conn->query("UPDATE posts SET status = 'deleted' WHERE room_id IN (SELECT id FROM rooms WHERE house_id = $house_id) AND status != 'deleted'");
        $conn->commit();
        echo json_encode(["status" => "success", "message" => "Nhà đã có lịch sử phát sinh nên đã được ngừng hoạt động thay vì xóa vật lý"]);
        exit;
    }

    $image_path = $house['image'] ?? '';
    $conn->query("DELETE FROM house_amenities WHERE house_id = $house_id");
    if (!$conn->query("DELETE FROM houses WHERE id = $house_id")) {
        throw new Exception($conn->error);
    }

    $conn->commit();
    if (!empty($image_path)) {
        $full_path = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/houses/" . $image_path;
        if (file_exists($full_path)) @unlink($full_path);
    }

    echo json_encode(["status" => "success", "message" => "Xóa nhà thành công"]);
} catch (Exception $e) {
    if ($conn) $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
