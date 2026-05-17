<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

$sql = "SELECT r.*, h.house_name, rm.room_name 
        FROM receipts r
        JOIN houses h ON r.house_id = h.id
        LEFT JOIN rooms rm ON r.room_id = rm.id
        WHERE 1=1 ";

// 🛡️ PHÂN QUYỀN
if ($role === 'admin') {
    // Admin thấy hết
} else if ($role === 'manager' && $managed_house_id > 0) {
    $sql .= " AND r.house_id = $managed_house_id ";
} else {
    // Landlord mặc định
    $sql .= " AND h.user_id = $user_id ";
}

if ($id > 0) {
    $sql .= " AND r.id = $id ";
} else {
    if ($house_id > 0) $sql .= " AND r.house_id = $house_id ";
}

$sql .= " ORDER BY r.receipt_date DESC, r.id DESC";
$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;

if ($id > 0 && count($data) > 0) {
    echo json_encode(["status" => "success", "data" => $data[0]]);
} else {
    echo json_encode(["status" => "success", "data" => $data]);
}
?>
