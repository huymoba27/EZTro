<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'save';
$id = isset($_POST['id']) ? (int)$_POST['id'] : (isset($_POST['incident_id']) ? (int)$_POST['incident_id'] : 0);
$room_id = isset($_POST['room_id']) ? (int)$_POST['room_id'] : 0;
$tenant_id = isset($_POST['tenant_id']) ? (int)$_POST['tenant_id'] : 0;
$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$title = isset($_POST['title']) ? $conn->real_escape_string($_POST['title']) : '';
$desc = isset($_POST['description']) ? $conn->real_escape_string($_POST['description']) : '';
$status = isset($_POST['status']) ? $conn->real_escape_string($_POST['status']) : 'pending';
$repair_cost = isset($_POST['repair_cost']) ? (float)$_POST['repair_cost'] : 0;
$manager_id = isset($_POST['manager_id']) ? (int)$_POST['manager_id'] : null;
$date = date('Y-m-d H:i:s');

try {
    $auth = qltro_auth_context($conn);
    if ($action === 'delete') {
        if ($id <= 0) throw new Exception("Thiếu ID sự cố");
        $incident_house = $conn->query("SELECT h.id AS house_id FROM incidents i JOIN rooms r ON i.room_id = r.id JOIN houses h ON r.house_id = h.id WHERE i.id = $id LIMIT 1")->fetch_assoc();
        qltro_assert_can_access_house($conn, $auth, (int)($incident_house['house_id'] ?? 0), "Bạn không có quyền thao tác với sự cố này");
        $stmt = $conn->prepare("DELETE FROM incidents WHERE id = ?");
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Xóa sự cố thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    if ($action === 'update_status') {
        if ($id <= 0) throw new Exception("Thiếu ID sự cố");
        $incident_house = $conn->query("SELECT h.id AS house_id FROM incidents i JOIN rooms r ON i.room_id = r.id JOIN houses h ON r.house_id = h.id WHERE i.id = $id LIMIT 1")->fetch_assoc();
        qltro_assert_can_access_house($conn, $auth, (int)($incident_house['house_id'] ?? 0), "Bạn không có quyền thao tác với sự cố này");
        $stmt = $conn->prepare("UPDATE incidents SET status = ?, repair_cost = ?, manager_id = ? WHERE id = ?");
        $stmt->bind_param("sdii", $status, $repair_cost, $manager_id, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật trạng thái thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    // Mặc định: báo sự cố mới
    if ($room_id <= 0 || $title === '') throw new Exception("Thiếu thông tin báo sự cố");

    if (($auth["role"] ?? "guest") !== "tenant") {
        qltro_assert_can_access_room($conn, $auth, $room_id);
    }

    $tenant_lookup_id = $tenant_id;
    $tenant_sql = "SELECT id FROM tenants 
                   WHERE room_id = $room_id 
                     AND status = 'active' 
                     AND deleted_at IS NULL
                     AND (
                        id = $tenant_lookup_id
                        OR user_id = $tenant_lookup_id
                        OR user_id = $user_id
                        OR (user_id IS NULL AND phone IN (SELECT phone FROM users WHERE id IN ($tenant_lookup_id, $user_id)))
                     )
                   LIMIT 1";
    $tenant_row = $conn->query($tenant_sql)->fetch_assoc();
    if (!$tenant_row) {
        throw new Exception("Không tìm thấy khách thuê đang hoạt động của phòng này");
    }
    $tenant_id = (int)$tenant_row['id'];

    $owner_row = $conn->query("SELECT h.user_id AS landlord_id
                               FROM rooms r
                               JOIN houses h ON r.house_id = h.id
                               WHERE r.id = $room_id
                               LIMIT 1")->fetch_assoc();
    $landlord_id = (int)($owner_row['landlord_id'] ?? 0);

    $stmt = $conn->prepare("INSERT INTO incidents (room_id, tenant_id, title, description, status, created_at) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("iissss", $room_id, $tenant_id, $title, $desc, $status, $date);
    
    if ($stmt->execute()) {
        echo json_encode([
            "status" => "success",
            "message" => "Báo sự cố thành công",
            "data" => [
                "id" => $stmt->insert_id,
                "tenant_id" => $tenant_id,
                "landlord_id" => $landlord_id
            ]
        ]);
    } else {
        throw new Exception($stmt->error);
    }

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
