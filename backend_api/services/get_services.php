<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

if ($house_id === 0) {
    // Trang TẤT CẢ NHÀ: Nhóm theo tên và đơn vị để đếm số lượng nhà (Có lọc quyền)
    $where = " WHERE 1=1 ";
    if ($role === 'manager' && $managed_house_id > 0) {
        $where .= " AND house_id IN (SELECT id FROM houses WHERE id = $managed_house_id AND status = 'active') ";
    } else if ($role !== 'admin') {
        $where .= " AND house_id IN (SELECT id FROM houses WHERE user_id = $user_id AND status = 'active') ";
    } else {
        $where .= " AND house_id IN (SELECT id FROM houses WHERE status = 'active') ";
    }

    $sql = "SELECT service_name, unit, COUNT(house_id) as total_houses 
            FROM services 
            $where
            GROUP BY service_name, unit 
            ORDER BY service_name ASC";
} else {
    // Trang TỪNG NHÀ: Lấy chi tiết giá của riêng nhà đó
    qltro_assert_can_access_house($conn, $auth, $house_id);
    $sql = "SELECT s.* FROM services s JOIN houses h ON s.house_id = h.id WHERE s.house_id = $house_id AND h.status = 'active' ORDER BY s.id DESC";
}

$result = $conn->query($sql);
$services = [];
while($row = $result->fetch_assoc()) {
    $services[] = $row;
}
echo json_encode(["status" => "success", "data" => $services]);
?>
