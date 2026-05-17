<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$room_id = isset($_GET['room_id']) ? (int)$_GET['room_id'] : 0;
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$month = isset($_GET['month']) ? (int)$_GET['month'] : 0;
$year = isset($_GET['year']) ? (int)$_GET['year'] : 0;
$role = $_GET['role'] ?? 'landlord';
$action = $_GET['action'] ?? '';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

$invoice_scope = "";
if ($role === 'tenant') {
    $invoice_scope = " AND (it.user_id = $user_id 
        OR (it.user_id IS NULL AND it.status = 'active' AND it.deleted_at IS NULL AND it.phone IN (SELECT phone FROM users WHERE id = $user_id))
        OR i.contract_id IN (
            SELECT c2.id
            FROM contracts c2
            JOIN tenants t2 ON c2.room_id = t2.room_id
            WHERE t2.user_id = $user_id
              AND t2.status = 'active'
              AND c2.status = 'active'
        )) ";
} else if ($role === 'manager' && $managed_house_id > 0) {
    $invoice_scope = " AND r.house_id = $managed_house_id ";
} else if ($role !== 'admin') {
    $invoice_scope = " AND h.user_id = $user_id ";
}

// ---------------------------------------------------------
// 1. ACTION: SUMMARY (TÍNH TOÁN HÓA ĐƠN TẠM TÍNH)
// ---------------------------------------------------------
if ($action === 'summary' && $room_id > 0) {
    qltro_assert_can_access_room($conn, $auth, $room_id);
    $contract = $conn->query("SELECT * FROM contracts WHERE room_id = $room_id AND status = 'active' LIMIT 1")->fetch_assoc();
    if (!$contract) {
        echo json_encode(["status" => "error", "message" => "Phòng này chưa có hợp đồng!"]); exit;
    }
    $contract_id = $contract['id'];
    $meter = $conn->query("SELECT * FROM meter_readings WHERE contract_id = $contract_id AND billing_month = $month AND billing_year = $year LIMIT 1")->fetch_assoc();

    $is_chot_so = false;
    if ($meter) {
        $old_elec = $meter['old_electric']; $new_elec = $meter['new_electric'];
        $old_water = $meter['old_water']; $new_water = $meter['new_water'];
        $is_chot_so = true;
    } else {
        $last_meter = $conn->query("SELECT new_electric, new_water FROM meter_readings WHERE contract_id = $contract_id ORDER BY id DESC LIMIT 1")->fetch_assoc();
        $old_elec = $last_meter['new_electric'] ?? $contract['start_electric_index'];
        $old_water = $last_meter['new_water'] ?? $contract['start_water_index'];
        $new_elec = 0; $new_water = 0;
    }

    $service_res = $conn->query("SELECT service_name, service_price, unit, charge_type FROM contract_services WHERE contract_id = $contract_id");
    $details = []; $total_amount = floatval($contract['rent_price']);
    $details[] = [
        "name" => "Tiền phòng", 
        "quantity" => 1, 
        "price" => floatval($contract['rent_price']), 
        "unit" => "Phòng", 
        "subtotal" => floatval($contract['rent_price']),
        "type" => "room"
    ];

    while ($s = $service_res->fetch_assoc()) {
        $name = $s['service_name']; $price = floatval($s['service_price']); $type = $s['charge_type']; $unit = $s['unit']; $qty = 1;
        $logic_type = "service";
        if (strpos($name, 'Điện') !== false) $logic_type = "electric";
        else if (strpos($name, 'Nước') !== false) $logic_type = "water";

        switch ($type) {
            case 'per_meter':
                if ($is_chot_so) {
                    $qty = ($logic_type === 'electric') ? ($new_elec - $old_elec) : ($new_water - $old_water);
                } else { $qty = 0; }
                break;
            case 'per_vehicle':
                $count_xe = $conn->query("SELECT COUNT(*) as total FROM vehicles v JOIN tenants t ON v.tenant_id = t.id WHERE t.room_id = $room_id")->fetch_assoc();
                $qty = intval($count_xe['total'] ?? 0); break;
            case 'per_person':
                $count_people = $conn->query("SELECT current_tenants FROM rooms WHERE id = $room_id")->fetch_assoc();
                $qty = intval($count_people['current_tenants'] ?? 1); break;
            default: $qty = 1; break;
        }
        $subtotal = $qty * $price; $total_amount += $subtotal;
        $details[] = ["name" => $name, "quantity" => $qty, "price" => $price, "unit" => $unit, "subtotal" => $subtotal, "type" => $logic_type];
    }
    echo json_encode(["status" => $is_chot_so ? "success" : "pending", "data" => ["old_elec" => (int)$old_elec, "new_elec" => (int)$new_elec, "old_water" => (int)$old_water, "new_water" => (int)$new_water, "details" => $details, "total_amount" => $total_amount]]);
    exit;
}

// ---------------------------------------------------------
// 2. ACTION: HOUSES_READY (DANH SÁCH NHÀ CHỜ LẬP HÓA ĐƠN)
// ---------------------------------------------------------
if ($action === 'houses_ready') {
    $sql = "SELECT DISTINCT h.id, h.house_name, h.address_detail 
            FROM houses h
            JOIN rooms r ON h.id = r.house_id
            JOIN contracts c ON r.id = c.room_id
            LEFT JOIN invoices i ON c.id = i.contract_id AND i.billing_month = $month AND i.billing_year = $year
            WHERE c.status = 'active' AND i.id IS NULL ";
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
// 3. ACTION: ROOMS_READY (DANH SÁCH PHÒNG CHỜ LẬP HÓA ĐƠN)
// ---------------------------------------------------------
if ($action === 'rooms_ready' && $house_id > 0) {
    qltro_assert_can_access_house($conn, $auth, $house_id);
    $sql = "SELECT r.*, c.tenant_id, h.house_name 
            FROM rooms r
            JOIN contracts c ON r.id = c.room_id
            JOIN houses h ON r.house_id = h.id
            LEFT JOIN invoices i ON c.id = i.contract_id AND i.billing_month = $month AND i.billing_year = $year
            WHERE r.house_id = $house_id AND c.status = 'active' AND i.id IS NULL";
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

// ---------------------------------------------------------
// 4. ACTION: STATUS_CHECK (KIỂM TRA TRẠNG THÁI HÓA ĐƠN)
// ---------------------------------------------------------
// 4. ACTION: STATUS_CHECK (KIỂM TRA TRẠNG THÁI HÓA ĐƠN)
// ---------------------------------------------------------
if ($action === 'status_check') {
    if ($id > 0) {
        // Kiểm tra trạng thái thanh toán của 1 hóa đơn cụ thể
        $check_sql = "SELECT i.id, i.status
                      FROM invoices i
                      JOIN rooms r ON i.room_id = r.id
                      JOIN houses h ON r.house_id = h.id
                      LEFT JOIN contracts ic ON i.contract_id = ic.id
                      LEFT JOIN tenants it ON ic.tenant_id = it.id
                      WHERE i.id = $id $invoice_scope
                      LIMIT 1";
        $check = $conn->query($check_sql)->fetch_assoc();
        echo json_encode(["status" => "success", "is_billed" => $check ? true : false, "invoice_status" => $check ? $check['status'] : null]);
    } else if ($room_id > 0) {
        // Tìm hợp đồng active của phòng
        qltro_assert_can_access_room($conn, $auth, $room_id);
        $c_res = $conn->query("SELECT id FROM contracts WHERE room_id = $room_id AND status = 'active' LIMIT 1");
        if ($c_res->num_rows > 0) {
            $c_id = $c_res->fetch_assoc()['id'];
            $check = $conn->query("SELECT id FROM invoices WHERE contract_id = $c_id AND billing_month = $month AND billing_year = $year LIMIT 1")->fetch_assoc();
            echo json_encode(["status" => "success", "is_billed" => $check ? true : false, "invoice_id" => $check ? $check['id'] : null]);
        } else {
            echo json_encode(["status" => "success", "is_billed" => false, "message" => "Phòng không có hợp đồng hoạt động"]);
        }
    }
    exit;
}

// ---------------------------------------------------------
// 5. MẶC ĐỊNH: DANH SÁCH HÓA ĐƠN HOẶC CHI TIẾT
// ---------------------------------------------------------
$sql = "SELECT i.*, r.room_name, h.house_name, h.id as house_id 
        FROM invoices i
        JOIN rooms r ON i.room_id = r.id
        JOIN houses h ON r.house_id = h.id
        LEFT JOIN contracts ic ON i.contract_id = ic.id
        LEFT JOIN tenants it ON ic.tenant_id = it.id ";

if ($id > 0) {
    $sql .= " WHERE i.id = $id $invoice_scope ";
} else {
    $sql .= " WHERE 1=1 ";
    if ($role === 'tenant') {
        $sql .= $invoice_scope;
        if ($room_id > 0) {
            $sql .= " AND i.room_id = $room_id ";
        }
    } else if ($role === 'manager' && $managed_house_id > 0) {
        $sql .= " AND r.house_id = $managed_house_id ";
    } else if ($role !== 'admin') {
        $sql .= " AND h.user_id = $user_id ";
    }
    if ($house_id > 0) $sql .= " AND h.id = $house_id ";
    if ($room_id > 0 && $role !== 'tenant') $sql .= " AND i.room_id = $room_id ";
    if ($month > 0) $sql .= " AND i.billing_month = $month ";
    if ($year > 0) $sql .= " AND i.billing_year = $year ";
}

$sql .= " ORDER BY i.id DESC";
$result = $conn->query($sql);
$data = [];

while ($row = $result->fetch_assoc()) {
    $inv_id = $row['id'];
    // Lấy chi tiết dịch vụ cho từng hóa đơn
    $details = [];
    $d_res = $conn->query("SELECT service_name as name, amount as subtotal FROM invoice_details WHERE invoice_id = $inv_id");
    while ($d_row = $d_res->fetch_assoc()) {
        $qty = 1; $unit = "";
        if (preg_match('/SL:\s*([\d\.]+)\s*([\p{L}\p{N}]+)/u', $d_row['name'], $matches)) {
            $qty = floatval($matches[1]); $unit = $matches[2];
        }
        $d_row['quantity'] = $qty; $d_row['unit'] = $unit;
        $d_row['unit_price'] = ($qty > 0) ? (floatval($d_row['subtotal']) / $qty) : floatval($d_row['subtotal']);
        $details[] = $d_row;
    }
    $room_amount = 0;
    $service_amount = 0;
    foreach ($details as $d) {
        $lowerName = mb_strtolower($d['name'], 'UTF-8');
        // Only count 'Tiền phòng' as room_amount
        if ($lowerName === 'tiền phòng' || strpos($lowerName, 'tiền phòng (') === 0) {
            $room_amount += $d['subtotal'];
        } else {
            $service_amount += $d['subtotal'];
        }
    }
    $row['room_amount'] = $room_amount;
    $row['service_amount'] = $service_amount;
    $row['details'] = $details;
    $data[] = $row;
}

if ($id > 0 && count($data) > 0) {
    // Lấy lịch sử thay đổi (Audit Logs)
    $logs = [];
    $log_sql = "SELECT l.*, IFNULL(u.full_name, 'Hệ thống') as user_name, IFNULL(u.role, 'system') as user_role 
                FROM invoice_logs l 
                LEFT JOIN users u ON l.user_id = u.id 
                WHERE l.invoice_id = $id 
                ORDER BY l.created_at DESC";
    $l_res = $conn->query($log_sql);
    while($l_row = $l_res->fetch_assoc()) $logs[] = $l_row;
    $data[0]['logs'] = $logs;

    echo json_encode(["status" => "success", "data" => $data[0]]);
} else {
    echo json_encode(["status" => "success", "data" => $data]);
}
?>
