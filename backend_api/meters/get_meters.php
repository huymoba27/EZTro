<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$room_id = isset($_GET['room_id']) ? (int)$_GET['room_id'] : 0;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$month = isset($_GET['month']) ? (int)$_GET['month'] : (int)date('m');
$year = isset($_GET['year']) ? (int)$_GET['year'] : (int)date('Y');
$role = $_GET['role'] ?? 'landlord';
$action = $_GET['action'] ?? 'status';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

if ($action === 'status') {
    $where = ($house_id > 0) ? " AND r.house_id = $house_id " : "";
    if ($role === 'manager' && $managed_house_id > 0) {
        $where .= " AND r.house_id = $managed_house_id ";
    } else if ($role !== 'admin') {
        $where .= " AND h.user_id = $user_id ";
    }

    $sql = "SELECT m.id, r.id as room_id, r.room_name, h.house_name, r.status,
                   m.new_electric, m.new_water, m.electric_image, m.water_image,
                   COALESCE(m.old_electric, (SELECT new_electric FROM meter_readings WHERE contract_id = c.id AND (billing_year < $year OR (billing_year = $year AND billing_month < $month)) ORDER BY billing_year DESC, billing_month DESC LIMIT 1), c.start_electric_index, 0) as old_electric,
                   COALESCE(m.old_water, (SELECT new_water FROM meter_readings WHERE contract_id = c.id AND (billing_year < $year OR (billing_year = $year AND billing_month < $month)) ORDER BY billing_year DESC, billing_month DESC LIMIT 1), c.start_water_index, 0) as old_water,
                   m.created_at as date_done, c.id as contract_id, c.tenant_id,
                   (SELECT id FROM invoices WHERE contract_id = c.id AND billing_month = $month AND billing_year = $year LIMIT 1) as invoice_id
            FROM rooms r
            JOIN houses h ON r.house_id = h.id
            LEFT JOIN contracts c ON r.id = c.room_id AND c.status = 'active'
            LEFT JOIN meter_readings m ON c.id = m.contract_id AND m.billing_month = $month AND m.billing_year = $year
            WHERE 1=1 $where
            ORDER BY r.room_name ASC";

    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $row['id'] = (int)$row['id'];
        $row['room_id'] = (int)$row['room_id'];
        $row['new_electric'] = (int)$row['new_electric'];
        $row['new_water'] = (int)$row['new_water'];
        $row['old_electric'] = (int)$row['old_electric'];
        $row['old_water'] = (int)$row['old_water'];
        $data[] = $row;
    }
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

if ($action === 'pending_houses') {
    $sql = "SELECT DISTINCT h.id, h.house_name
            FROM houses h
            JOIN rooms r ON h.id = r.house_id
            JOIN contracts c ON r.id = c.room_id AND c.status = 'active'
            LEFT JOIN meter_readings m ON c.id = m.contract_id AND m.billing_month = $month AND m.billing_year = $year
            WHERE m.id IS NULL";
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

if ($action === 'pending_rooms' && $house_id > 0) {
    qltro_assert_can_access_house($conn, $auth, $house_id);
    $sql = "SELECT r.id, r.room_name, h.house_name, c.id AS contract_id, c.tenant_id
            FROM rooms r
            JOIN houses h ON r.house_id = h.id
            JOIN contracts c ON r.id = c.room_id AND c.status = 'active'
            LEFT JOIN meter_readings m ON c.id = m.contract_id AND m.billing_month = $month AND m.billing_year = $year
            WHERE r.house_id = $house_id AND m.id IS NULL";
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

if ($action === 'history' && $room_id > 0) {
    qltro_assert_can_access_room($conn, $auth, $room_id);
    $sql = "SELECT * FROM meter_readings WHERE room_id = $room_id ORDER BY billing_year DESC, billing_month DESC";
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

if ($action === 'room_latest_reading' && $room_id > 0) {
    qltro_assert_can_access_room($conn, $auth, $room_id);
    $sql_meter = "SELECT new_electric as old_electric, new_water as old_water
                  FROM meter_readings
                  WHERE room_id = $room_id
                  ORDER BY billing_year DESC, billing_month DESC, id DESC LIMIT 1";
    $res = $conn->query($sql_meter)->fetch_assoc();

    if (!$res) {
        $sql_contract = "SELECT start_electric_index as old_electric, start_water_index as old_water
                         FROM contracts
                         WHERE room_id = $room_id
                         ORDER BY id DESC LIMIT 1";
        $res = $conn->query($sql_contract)->fetch_assoc();
    }

    if (!$res) {
        $res = ["old_electric" => 0, "old_water" => 0];
    }

    echo json_encode(["status" => "success", "data" => $res]);
    exit;
}

if ($action === 'last_reading' && $room_id > 0) {
    qltro_assert_can_access_room($conn, $auth, $room_id);
    $active_contract = $conn->query("SELECT id AS contract_id, tenant_id, start_electric_index, start_water_index
                                     FROM contracts
                                     WHERE room_id = $room_id AND status = 'active'
                                     ORDER BY id DESC LIMIT 1")->fetch_assoc();

    if (!$active_contract) {
        echo json_encode(["status" => "error", "message" => "Phòng này chưa có hợp đồng đang hoạt động."]);
        exit;
    }

    $contract_id = (int)$active_contract['contract_id'];
    $sql_meter = "SELECT new_electric as old_electric, new_water as old_water
                  FROM meter_readings
                  WHERE contract_id = $contract_id
                  ORDER BY billing_year DESC, billing_month DESC, id DESC LIMIT 1";
    $res = $conn->query($sql_meter)->fetch_assoc();

    if (!$res) {
        $res = [
            "old_electric" => $active_contract['start_electric_index'] ?? 0,
            "old_water" => $active_contract['start_water_index'] ?? 0,
        ];
    }

    $res['contract_id'] = $contract_id;
    $res['tenant_id'] = $active_contract['tenant_id'];

    echo json_encode(["status" => "success", "data" => $res]);
    exit;
}

echo json_encode(["status" => "error", "message" => "Yêu cầu không hợp lệ."]);
?>
