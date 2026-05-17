<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0; // ID của chủ trọ hoặc khách thuê
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);
$tenant_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$room_id = isset($_GET['room_id']) ? (int)$_GET['room_id'] : 0;

$sql = "SELECT t.*, r.room_name, h.house_name, r.house_id 
        FROM tenants t
        JOIN rooms r ON t.room_id = r.id
        JOIN houses h ON r.house_id = h.id
        WHERE t.deleted_at IS NULL ";

// 1. 🛡️ PHÂN QUYỀN
if ($role === 'admin') {
    // Admin thấy hết
} else if ($role === 'tenant') {
    $sql .= " AND (t.user_id = $user_id OR (t.user_id IS NULL AND t.status = 'active' AND t.deleted_at IS NULL AND t.phone IN (SELECT phone FROM users WHERE id = $user_id))) ";
} else if ($role === 'manager' && $managed_house_id > 0) {
    // Manager: Thấy khách của nhà mình quản lý
    $sql .= " AND r.house_id = $managed_house_id ";
} else {
    // Landlord: Thấy khách thuê của các nhà mình sở hữu
    $sql .= " AND h.user_id = $user_id ";
}

// 2. 🔍 BỘ LỌC CHI TIẾT
if ($tenant_id > 0) {
    $sql .= " AND t.id = $tenant_id ";
}
if ($house_id > 0) {
    $sql .= " AND r.house_id = $house_id ";
}
if ($room_id > 0) {
    $sql .= " AND t.room_id = $room_id ";
}

$sql .= " ORDER BY t.id DESC";

$result = $conn->query($sql);
$data = [];

if ($result) {
    while ($row = $result->fetch_assoc()) {
        if ($tenant_id > 0) {
            $t_id = $row['id'];
            $logs = [];
            $log_sql = "SELECT l.*, IFNULL(u.full_name, 'Hệ thống') as user_name, IFNULL(u.role, 'system') as user_role 
                        FROM tenant_logs l 
                        LEFT JOIN users u ON l.user_id = u.id 
                        WHERE l.tenant_id = $t_id 
                        ORDER BY l.created_at DESC";
            $l_res = $conn->query($log_sql);
            if ($l_res) {
                while($l_row = $l_res->fetch_assoc()) $logs[] = $l_row;
            }
            $row['logs'] = $logs;
        }
        $data[] = $row;
    }
    
    if ($tenant_id > 0 && count($data) > 0) {
        echo json_encode(["status" => "success", "data" => $data[0]]);
    } else {
        echo json_encode(["status" => "success", "data" => $data]);
    }
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}
?>
