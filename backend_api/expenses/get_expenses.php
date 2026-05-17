<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$month = isset($_GET['month']) ? (int)$_GET['month'] : 0;
$year = isset($_GET['year']) ? (int)$_GET['year'] : 0;
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

$sql = "SELECT e.*, h.house_name, rm.room_name 
        FROM expenses e
        JOIN houses h ON e.house_id = h.id
        LEFT JOIN rooms rm ON e.room_id = rm.id
        WHERE 1=1 ";

// 🛡️ PHÂN QUYỀN
if ($role === 'admin') {
    // Admin thấy hết
} else if ($role === 'manager' && $managed_house_id > 0) {
    $sql .= " AND e.house_id = $managed_house_id ";
} else {
    // Landlord mặc định
    $sql .= " AND h.user_id = $user_id ";
}

if ($id > 0) {
    $sql .= " AND e.id = $id ";
} else {
    if ($house_id > 0) $sql .= " AND e.house_id = $house_id ";
    if ($month > 0) $sql .= " AND MONTH(e.expense_date) = $month ";
    if ($year > 0) $sql .= " AND YEAR(e.expense_date) = $year ";
}

$sql .= " ORDER BY e.expense_date DESC, e.id DESC";
$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;

if ($id > 0 && count($data) > 0) {
    echo json_encode(["status" => "success", "data" => $data[0]]);
} else {
    echo json_encode(["status" => "success", "data" => $data]);
}
?>
