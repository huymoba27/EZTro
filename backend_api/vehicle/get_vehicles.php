<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$room_id = isset($_GET['room_id']) ? (int)$_GET['room_id'] : 0;
$action = $_GET['action'] ?? 'all';
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

// ---------------------------------------------------------
// 1. ACTION: UNREGISTERED_HOUSES (NHÀ CÓ PHÒNG CÓ DỊCH VỤ XE)
// ---------------------------------------------------------
if ($action === 'unregistered_houses') {
    $sql = "SELECT DISTINCT h.id, h.house_name 
            FROM houses h
            JOIN rooms r ON h.id = r.house_id
            JOIN contracts c ON r.id = c.room_id AND c.status = 'active'
            JOIN contract_services cs ON c.id = cs.contract_id
            WHERE cs.service_name LIKE '%xe%'";
    if ($role === 'manager' && $managed_house_id > 0) {
        $sql .= " AND h.id = $managed_house_id ";
    } else if ($role !== 'admin') {
        $sql .= " AND h.user_id = $user_id ";
    }
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

// ---------------------------------------------------------
// 2. ACTION: PENDING_ROOMS (PHÒNG CÓ DỊCH VỤ XE)
// ---------------------------------------------------------
if ($action === 'pending_rooms' && $house_id > 0) {
    qltro_assert_can_access_house($conn, $auth, $house_id);
    $sql = "SELECT r.id, r.room_name, h.house_name, t.id as tenant_id, t.tenant_name
            FROM rooms r
            JOIN houses h ON r.house_id = h.id
            JOIN tenants t ON r.id = t.room_id AND t.is_representative = 1
            JOIN contracts c ON r.id = c.room_id AND c.status = 'active'
            JOIN contract_services cs ON c.id = cs.contract_id
            WHERE r.house_id = $house_id AND cs.service_name LIKE '%xe%'";
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

// ---------------------------------------------------------
// 3. ACTION: TENANTS (DANH SÁCH KHÁCH THUÊ ĐỂ CHỌN CHỦ XE)
// ---------------------------------------------------------
if ($action === 'tenants' && ($house_id > 0 || $room_id > 0)) {
    if ($room_id > 0) {
        qltro_assert_can_access_room($conn, $auth, $room_id);
    } else {
        qltro_assert_can_access_house($conn, $auth, $house_id);
    }
    $where = " WHERE t.status = 'active' ";
    if ($room_id > 0) {
        $where .= " AND t.room_id = $room_id ";
    } else {
        $where .= " AND r.house_id = $house_id ";
    }

    $sql = "SELECT t.id, t.tenant_name, r.room_name 
            FROM tenants t 
            JOIN rooms r ON t.room_id = r.id 
            $where";
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $t_id = $row['id'];
        $v_res = $conn->query("SELECT * FROM vehicles WHERE tenant_id = $t_id");
        $vehicles = [];
        while($v_row = $v_res->fetch_assoc()) $vehicles[] = $v_row;
        $row['vehicles'] = $vehicles;
        $data[] = $row;
    }
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

// ---------------------------------------------------------
// 4. MẶC ĐỊNH: LẤY TẤT CẢ XE (CÓ PHÂN QUYỀN)
// ---------------------------------------------------------
$sql = "SELECT v.*, t.tenant_name, r.room_name, r.id as room_id, h.house_name, h.id as house_id 
        FROM vehicles v
        JOIN tenants t ON v.tenant_id = t.id
        JOIN rooms r ON t.room_id = r.id
        JOIN houses h ON r.house_id = h.id WHERE 1=1 ";

if ($role === 'manager' && $managed_house_id > 0) {
    $sql .= " AND h.id = $managed_house_id ";
} else if ($role !== 'admin') {
    $sql .= " AND h.user_id = $user_id ";
}
if ($house_id > 0) $sql .= " AND h.id = $house_id ";

$sql .= " ORDER BY v.created_at DESC";
$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;
echo json_encode(["status" => "success", "data" => $data]);
?>
