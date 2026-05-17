<?php
function qltro_param($key, $source = null, $default = null) {
    if (is_array($source) && array_key_exists($key, $source)) return $source[$key];
    if (is_object($source) && isset($source->{$key})) return $source->{$key};
    if (isset($_POST[$key])) return $_POST[$key];
    if (isset($_GET[$key])) return $_GET[$key];
    return $default;
}

function qltro_json_error($message, $http_code = 200) {
    if ($http_code !== 200 && !headers_sent()) http_response_code($http_code);
    echo json_encode(["status" => "error", "message" => $message]);
    exit;
}

function qltro_auth_context($conn, $source = null) {
    $user_id = (int)qltro_param('user_id', $source, 0);
    $ctx = [
        "user_id" => $user_id,
        "role" => "guest",
        "managed_house_id" => 0,
        "verified" => false,
    ];

    if ($user_id <= 0) return $ctx;

    $stmt = $conn->prepare("SELECT id, role, managed_house_id FROM users WHERE id = ? LIMIT 1");
    if (!$stmt) return $ctx;
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $res = $stmt->get_result();
    if ($row = $res->fetch_assoc()) {
        $ctx["user_id"] = (int)$row["id"];
        $ctx["role"] = $row["role"] ?: "guest";
        $ctx["managed_house_id"] = (int)($row["managed_house_id"] ?? 0);
        $ctx["verified"] = true;
    }
    $stmt->close();
    return $ctx;
}

function qltro_apply_auth_context(&$user_id, &$role, &$managed_house_id, $ctx) {
    if (!$ctx["verified"]) {
        $user_id = 0;
        $role = "guest";
        $managed_house_id = 0;
        return;
    }
    $user_id = (int)$ctx["user_id"];
    $role = $ctx["role"];
    $managed_house_id = (int)$ctx["managed_house_id"];
}

function qltro_can_access_house($conn, $ctx, $house_id) {
    $house_id = (int)$house_id;
    if ($house_id <= 0 || !$ctx["verified"]) return false;
    if ($ctx["role"] === "admin") return true;
    if ($ctx["role"] === "manager") return (int)$ctx["managed_house_id"] === $house_id;
    if ($ctx["role"] === "landlord") {
        $uid = (int)$ctx["user_id"];
        $res = $conn->query("SELECT id FROM houses WHERE id = $house_id AND user_id = $uid LIMIT 1");
        return $res && $res->num_rows > 0;
    }
    return false;
}

function qltro_house_id_for_room($conn, $room_id) {
    $room_id = (int)$room_id;
    $row = $conn->query("SELECT house_id FROM rooms WHERE id = $room_id LIMIT 1")->fetch_assoc();
    return $row ? (int)$row["house_id"] : 0;
}

function qltro_house_id_for_contract($conn, $contract_id) {
    $contract_id = (int)$contract_id;
    $row = $conn->query("SELECT r.house_id FROM contracts c JOIN rooms r ON c.room_id = r.id WHERE c.id = $contract_id LIMIT 1")->fetch_assoc();
    return $row ? (int)$row["house_id"] : 0;
}

function qltro_house_id_for_invoice($conn, $invoice_id) {
    $invoice_id = (int)$invoice_id;
    $row = $conn->query("SELECT r.house_id FROM invoices i JOIN rooms r ON i.room_id = r.id WHERE i.id = $invoice_id LIMIT 1")->fetch_assoc();
    return $row ? (int)$row["house_id"] : 0;
}

function qltro_house_id_for_meter($conn, $meter_id) {
    $meter_id = (int)$meter_id;
    $row = $conn->query("SELECT r.house_id FROM meter_readings m JOIN rooms r ON m.room_id = r.id WHERE m.id = $meter_id LIMIT 1")->fetch_assoc();
    return $row ? (int)$row["house_id"] : 0;
}

function qltro_house_id_for_tenant($conn, $tenant_id) {
    $tenant_id = (int)$tenant_id;
    $row = $conn->query("SELECT r.house_id FROM tenants t JOIN rooms r ON t.room_id = r.id WHERE t.id = $tenant_id LIMIT 1")->fetch_assoc();
    return $row ? (int)$row["house_id"] : 0;
}

function qltro_house_id_for_vehicle($conn, $vehicle_id) {
    $vehicle_id = (int)$vehicle_id;
    $row = $conn->query("SELECT r.house_id FROM vehicles v JOIN tenants t ON v.tenant_id = t.id JOIN rooms r ON t.room_id = r.id WHERE v.id = $vehicle_id LIMIT 1")->fetch_assoc();
    return $row ? (int)$row["house_id"] : 0;
}

function qltro_house_id_for_table($conn, $table, $id) {
    $allowed = ["services", "receipts", "expenses", "deposits"];
    if (!in_array($table, $allowed, true)) return 0;
    $id = (int)$id;
    $row = $conn->query("SELECT house_id FROM $table WHERE id = $id LIMIT 1")->fetch_assoc();
    return $row ? (int)$row["house_id"] : 0;
}

function qltro_assert_can_access_house($conn, $ctx, $house_id, $message = "Bạn không có quyền thao tác với nhà này") {
    if (!qltro_can_access_house($conn, $ctx, $house_id)) qltro_json_error($message);
}

function qltro_assert_can_access_room($conn, $ctx, $room_id, $message = "Bạn không có quyền thao tác với phòng này") {
    qltro_assert_can_access_house($conn, $ctx, qltro_house_id_for_room($conn, $room_id), $message);
}

function qltro_assert_can_access_contract($conn, $ctx, $contract_id, $message = "Bạn không có quyền thao tác với hợp đồng này") {
    qltro_assert_can_access_house($conn, $ctx, qltro_house_id_for_contract($conn, $contract_id), $message);
}

function qltro_assert_can_access_invoice($conn, $ctx, $invoice_id, $message = "Bạn không có quyền thao tác với hóa đơn này") {
    qltro_assert_can_access_house($conn, $ctx, qltro_house_id_for_invoice($conn, $invoice_id), $message);
}

function qltro_assert_can_access_meter($conn, $ctx, $meter_id, $message = "Bạn không có quyền thao tác với chỉ số này") {
    qltro_assert_can_access_house($conn, $ctx, qltro_house_id_for_meter($conn, $meter_id), $message);
}

function qltro_assert_can_access_tenant($conn, $ctx, $tenant_id, $message = "Bạn không có quyền thao tác với khách thuê này") {
    qltro_assert_can_access_house($conn, $ctx, qltro_house_id_for_tenant($conn, $tenant_id), $message);
}

function qltro_assert_can_access_vehicle($conn, $ctx, $vehicle_id, $message = "Bạn không có quyền thao tác với xe này") {
    qltro_assert_can_access_house($conn, $ctx, qltro_house_id_for_vehicle($conn, $vehicle_id), $message);
}

function qltro_assert_can_access_table_row($conn, $ctx, $table, $id, $message = "Bạn không có quyền thao tác với dữ liệu này") {
    qltro_assert_can_access_house($conn, $ctx, qltro_house_id_for_table($conn, $table, $id), $message);
}

function qltro_assert_can_manage_house_profile($conn, $ctx, $house_id) {
    if (!$ctx["verified"]) qltro_json_error("Bạn cần đăng nhập để thực hiện thao tác này");
    if ($ctx["role"] === "manager") qltro_json_error("Quản lý không có quyền sửa hoặc xóa thông tin nhà trọ");
    qltro_assert_can_access_house($conn, $ctx, $house_id);
}
?>
