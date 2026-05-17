<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'save';
$id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
$house_id = isset($_POST['house_id']) ? (int)$_POST['house_id'] : 0;
$house_ids = isset($_POST['house_ids']) ? json_decode($_POST['house_ids']) : [];
$name = isset($_POST['service_name']) ? $conn->real_escape_string($_POST['service_name']) : '';
$price = isset($_POST['price']) ? (float)$_POST['price'] : 0;
$unit = isset($_POST['unit']) ? $conn->real_escape_string($_POST['unit']) : '';
$charge_type = isset($_POST['charge_type']) ? $conn->real_escape_string($_POST['charge_type']) : 'fixed';
$service_type = isset($_POST['service_type']) ? $conn->real_escape_string($_POST['service_type']) : 'other';

try {
    $auth = qltro_auth_context($conn);
    if ($action === 'delete') {
        if ($id <= 0) throw new Exception("Thiếu ID dịch vụ");
        qltro_assert_can_access_table_row($conn, $auth, "services", $id, "Bạn không có quyền thao tác với dịch vụ này");
        $used = $conn->query("SELECT contract_id FROM contract_services WHERE service_id = $id LIMIT 1")->fetch_assoc();
        if ($used) {
            throw new Exception("Dich vu da duoc gan vao hop dong, khong the xoa vat ly.");
        }
        $stmt = $conn->prepare("DELETE FROM services WHERE id = ?");
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Xóa dịch vụ thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    if ($action === 'update') {
        if ($id <= 0) throw new Exception("Thiếu ID dịch vụ");
        if ($name === '') throw new Exception("Tên dịch vụ không được để trống");
        if ($price <= 0) throw new Exception("Đơn giá dịch vụ phải lớn hơn 0");
        qltro_assert_can_access_table_row($conn, $auth, "services", $id, "Bạn không có quyền thao tác với dịch vụ này");
        $stmt = $conn->prepare("UPDATE services SET service_name = ?, price = ?, unit = ?, charge_type = ?, service_type = ? WHERE id = ?");
        $stmt->bind_param("sdsssi", $name, $price, $unit, $charge_type, $service_type, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    // MẶC ĐỊNH: THÊM MỚI (Hỗ trợ thêm cho nhiều nhà)
    if ($name === '' || (empty($house_ids) && $house_id <= 0)) throw new Exception("Thiếu thông tin dịch vụ hoặc nhà trọ");
    if ($price <= 0) throw new Exception("Đơn giá dịch vụ phải lớn hơn 0");
    
    if (empty($house_ids)) $house_ids = [$house_id];
    $errors = [];
    $success_count = 0;

    foreach ($house_ids as $h_id) {
        $h_id = intval($h_id);
        qltro_assert_can_access_house($conn, $auth, $h_id);
        // Kiểm tra trùng
        $check = $conn->query("SELECT id FROM services WHERE house_id = $h_id AND service_name = '$name'")->num_rows;
        if ($check > 0) {
            $h_info = $conn->query("SELECT house_name FROM houses WHERE id = $h_id")->fetch_assoc();
            $errors[] = $h_info['house_name'];
        } else {
            $stmt = $conn->prepare("INSERT INTO services (house_id, service_name, price, unit, charge_type, service_type) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt->bind_param("isdsss", $h_id, $name, $price, $unit, $charge_type, $service_type);
            if ($stmt->execute()) $success_count++;
        }
    }

    if (count($errors) > 0) {
        echo json_encode(["status" => "partial_error", "message" => "Nhà đã có dịch vụ này: " . implode(", ", $errors), "success_count" => $success_count]);
    } else {
        echo json_encode(["status" => "success", "message" => "Thêm dịch vụ thành công"]);
    }

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
