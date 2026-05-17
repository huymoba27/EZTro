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
$with_contracts = isset($_GET['with_contracts']) ? (bool)$_GET['with_contracts'] : false;
$include_inactive = isset($_GET['include_inactive']) && $_GET['include_inactive'] == '1';

// Query cơ bản (JOIN với bảng users để lấy tên và sđt chủ nhà)
$sql = "SELECT h.*, 
               u.full_name as owner_name, 
               u.phone as owner_phone,
               (SELECT full_name FROM users WHERE managed_house_id = h.id AND role = 'manager' LIMIT 1) as manager_name,
               (SELECT phone FROM users WHERE managed_house_id = h.id AND role = 'manager' LIMIT 1) as manager_phone,
               (SELECT id FROM users WHERE managed_house_id = h.id AND role = 'manager' LIMIT 1) as manager_id,
               (SELECT COUNT(*) FROM rooms WHERE house_id = h.id AND status != 'deleted') as total_rooms,
               (SELECT COUNT(*) FROM rooms WHERE house_id = h.id AND status IN ('empty', 'posted')) as total_empty_rooms,
               (SELECT IFNULL(SUM(current_tenants), 0) FROM rooms WHERE house_id = h.id AND status != 'deleted') as total_tenants
        FROM houses h
        JOIN users u ON h.user_id = u.id
        WHERE 1=1 ";

if (!$include_inactive) {
    $sql .= " AND h.status = 'active' ";
}

// 1. PHÂN QUYỀN
if ($role === 'admin') {
    // Admin thấy hết
} else if ($role === 'manager' && $managed_house_id > 0) {
    $sql .= " AND h.id = $managed_house_id ";
} else {
    // Landlord mặc định
    $sql .= " AND h.user_id = $user_id ";
}

// 2. LỌC CHỈ LẤY NHÀ CÓ HỢP ĐỒNG (Nếu yêu cầu)
if ($with_contracts) {
    $sql .= " AND h.id IN (SELECT DISTINCT r.house_id FROM rooms r JOIN contracts c ON r.id = c.room_id WHERE c.status = 'active') ";
}

$sql .= " ORDER BY h.id DESC";

$result = $conn->query($sql);
$data = [];

if ($result) {
    while ($row = $result->fetch_assoc()) {
        $house_id = $row['id'];
        
        // Lấy danh sách tiện ích của từng nhà
        $amenity_sql = "SELECT a.id, a.name 
                        FROM house_amenities ha 
                        JOIN amenities a ON ha.amenity_id = a.id 
                        WHERE ha.house_id = $house_id";
        $amenity_result = $conn->query($amenity_sql);
        $amenities = [];
        if ($amenity_result) {
            while ($a_row = $amenity_result->fetch_assoc()) {
                $amenities[] = $a_row;
            }
        }
        $row['amenities'] = $amenities;
        
        $data[] = $row;
    }
    echo json_encode(["status" => "success", "data" => $data]);
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}
?>
