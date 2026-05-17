<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);
$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$incident_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;

$sql = "SELECT i.*, r.room_name, h.house_name, t.tenant_name
        FROM incidents i
        JOIN rooms r ON i.room_id = r.id
        JOIN houses h ON r.house_id = h.id
        JOIN tenants t ON i.tenant_id = t.id
        WHERE 1=1 ";

// 🛡️ PHÂN QUYỀN
if ($role === 'admin') {
    // Admin thấy hết
} else if ($role === 'tenant') {
    // Khách thuê chỉ thấy sự cố mình báo
    $sql .= " AND i.tenant_id IN (SELECT id FROM tenants WHERE user_id = $user_id OR (user_id IS NULL AND status = 'active' AND deleted_at IS NULL AND phone IN (SELECT phone FROM users WHERE id = $user_id))) ";
} else if ($role === 'manager' && $managed_house_id > 0) {
    $sql .= " AND h.id = $managed_house_id ";
} else {
    // Chủ trọ thấy sự cố của nhà mình
    $sql .= " AND h.user_id = $user_id ";
}

if ($house_id > 0) $sql .= " AND h.id = $house_id ";
if ($incident_id > 0) $sql .= " AND i.id = $incident_id ";

$sql .= " ORDER BY i.id DESC";
$result = $conn->query($sql);

if ($incident_id > 0) {
    $row = $result->fetch_assoc();
    if ($row) echo json_encode(["status" => "success", "data" => $row]);
    else echo json_encode(["status" => "error", "message" => "Không tìm thấy sự cố"]);
} else {
    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);
}
?>
