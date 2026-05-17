<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'save';
$id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
$tenant_id = isset($_POST['tenant_id']) ? (int)$_POST['tenant_id'] : 0;
$type = isset($_POST['vehicle_type']) ? $conn->real_escape_string($_POST['vehicle_type']) : '';
$license = isset($_POST['license_plate']) ? $conn->real_escape_string($_POST['license_plate']) : '';
$brand = isset($_POST['brand']) ? $conn->real_escape_string($_POST['brand']) : '';
$color = isset($_POST['color']) ? $conn->real_escape_string($_POST['color']) : '';

try {
    $auth = qltro_auth_context($conn);
    if ($action === 'delete') {
        if ($id <= 0) throw new Exception("Thiếu ID xe");
        qltro_assert_can_access_vehicle($conn, $auth, $id);
        $stmt = $conn->prepare("DELETE FROM vehicles WHERE id = ?");
        $stmt->bind_param("i", $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Xóa xe thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    if ($tenant_id <= 0 || $license === '') throw new Exception("Thiếu thông tin chủ xe hoặc biển số");

    qltro_assert_can_access_tenant($conn, $auth, $tenant_id);

    if ($action === 'update') {
        if ($id <= 0) throw new Exception("Thiếu ID xe");
        qltro_assert_can_access_vehicle($conn, $auth, $id);
        $tenant_vehicle_stmt = $conn->prepare("SELECT id FROM vehicles WHERE tenant_id = ? AND id != ? LIMIT 1");
        $tenant_vehicle_stmt->bind_param("ii", $tenant_id, $id);
        $tenant_vehicle_stmt->execute();
        if ($tenant_vehicle_stmt->get_result()->num_rows > 0) {
            throw new Exception("Khách thuê này đã có phương tiện đăng ký.");
        }
        $tenant_vehicle_stmt->close();
        $check_stmt = $conn->prepare("SELECT id FROM vehicles WHERE plate_number = ? AND id != ? LIMIT 1");
        $check_stmt->bind_param("si", $license, $id);
        $check_stmt->execute();
        if ($check_stmt->get_result()->num_rows > 0) {
            throw new Exception("Biển số xe này đã được đăng ký trong hệ thống!");
        }
        $check_stmt->close();
        $stmt = $conn->prepare("UPDATE vehicles SET vehicle_type = ?, plate_number = ? WHERE id = ?");
        $stmt->bind_param("ssi", $type, $license, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
        else throw new Exception($stmt->error);
    } else {
        // SAVE (Insert)
        $tenant_vehicle_stmt = $conn->prepare("SELECT id FROM vehicles WHERE tenant_id = ? LIMIT 1");
        $tenant_vehicle_stmt->bind_param("i", $tenant_id);
        $tenant_vehicle_stmt->execute();
        if ($tenant_vehicle_stmt->get_result()->num_rows > 0) {
            throw new Exception("Khách thuê này đã có phương tiện đăng ký.");
        }
        $tenant_vehicle_stmt->close();

        // Kiểm tra biển số trùng (Dùng plate_number)
        $check_stmt = $conn->prepare("SELECT id FROM vehicles WHERE plate_number = ? LIMIT 1");
        $check_stmt->bind_param("s", $license);
        $check_stmt->execute();
        if ($check_stmt->get_result()->num_rows > 0) {
            throw new Exception("Biển số xe này đã được đăng ký trong hệ thống!");
        }
        $check_stmt->close();

        $stmt = $conn->prepare("INSERT INTO vehicles (tenant_id, vehicle_type, plate_number) VALUES (?, ?, ?)");
        $stmt->bind_param("iss", $tenant_id, $type, $license);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Đăng ký xe thành công", "id" => $stmt->insert_id]);
        else throw new Exception($stmt->error);
    }

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
