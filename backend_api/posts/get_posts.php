<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$action = $_GET['action'] ?? 'list';
$auth = qltro_auth_context($conn);
if ($user_id > 0) {
    qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);
}

$sql = "SELECT p.*, r.room_name, r.price as original_price, r.area, r.deposit, r.max_tenants, r.house_id,
               h.house_name, h.address_detail, h.ward, h.city, h.latitude, h.longitude, 
               u.full_name as owner_name, u.phone as owner_phone,
               (SELECT price FROM services WHERE house_id = h.id AND service_type = 'electric' LIMIT 1) as electric_price,
               (SELECT price FROM services WHERE house_id = h.id AND service_type = 'water' LIMIT 1) as water_price,
               (SELECT GROUP_CONCAT(a.name SEPARATOR ', ') FROM house_amenities ha JOIN amenities a ON ha.amenity_id = a.id WHERE ha.house_id = h.id) as house_amenities
        FROM posts p
        JOIN rooms r ON p.room_id = r.id
        JOIN houses h ON r.house_id = h.id
        JOIN users u ON h.user_id = u.id 
        WHERE 1=1 ";

if ($id > 0) {
    $sql .= " AND p.id = $id ";
} else {
    // PHÂN QUYỀN TRONG DANH SÁCH QUẢN LÝ TIN ĐĂNG
    if ($user_id > 0) {
        if ($role === 'manager' && $managed_house_id > 0) {
            $sql .= " AND h.id = $managed_house_id ";
        } else if ($role !== 'admin') {
            $sql .= " AND h.user_id = $user_id ";
        }
    } else {
        $sql .= " AND p.status = 'active' ";
    }
}

$sql .= " ORDER BY p.created_at DESC";
$result = $conn->query($sql);
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

if ($id > 0 && count($data) > 0) {
    echo json_encode(["status" => "success", "data" => $data[0]]);
} else {
    echo json_encode(["status" => "success", "data" => $data]);
}
?>
