<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
require_once dirname(__DIR__) . '/helpers/validation_helper.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $phone = qltro_normalize_phone($_POST['phone'] ?? '');
    $full_name = $_POST['full_name'] ?? null;
    $managed_house_id = $_POST['managed_house_id'] ?? null;
    $auth = qltro_auth_context($conn);

    if ($phone) {
        try {
            $phone = qltro_assert_valid_phone($phone);
        } catch (Exception $e) {
            echo json_encode(["status" => "error", "message" => $e->getMessage()]);
            exit;
        }
    }

    if (!$phone || !$full_name || !$managed_house_id) {
        echo json_encode(["status" => "error", "message" => "Vui lòng nhập đủ tên, SĐT và chọn nhà trọ khoản lý"]);
        exit;
    }
    if (!$auth["verified"] || !in_array($auth["role"], ["landlord", "admin"], true)) {
        echo json_encode(["status" => "error", "message" => "Bạn không có quyền cấp quyền quản lý"]);
        exit;
    }
    qltro_assert_can_access_house($conn, $auth, (int)$managed_house_id, "Bạn chỉ có thể cấp quản lý cho nhà thuộc quyền sở hữu của mình");

    // Kiểm tra xem SĐT này đã có trong bảng users chưa
    $stmt = $conn->prepare("SELECT id FROM users WHERE phone = ? OR username = ?");
    $stmt->bind_param("ss", $phone, $phone);
    $stmt->execute();
    $res = $stmt->get_result();

    if ($res->num_rows > 0) {
        // Tài khoản đã có -> Cập nhật quyền
        $row = $res->fetch_assoc();
        $update = $conn->prepare("UPDATE users SET role = 'manager', managed_house_id = ?, full_name = ? WHERE id = ?");
        $update->bind_param("isi", $managed_house_id, $full_name, $row['id']);
        if ($update->execute()) {
             echo json_encode(["status" => "success", "message" => "Đã thăng cấp tài khoản có sẵn lên Quản lý nhân viên."]);
        } else {
             echo json_encode(["status" => "error", "message" => "Lỗi cấp quyền: " . $conn->error]);
        }
    } else {
        // Tạo tài khoản mới hoàn toàn
        // Username mặc định là SĐT, Password mặc định cũng là SĐT (đã hash)
        $hashed_password = password_hash($phone, PASSWORD_DEFAULT);
        $insert = $conn->prepare("INSERT INTO users (username, password, phone, full_name, role, managed_house_id) VALUES (?, ?, ?, ?, 'manager', ?)");
        $insert->bind_param("ssssi", $phone, $hashed_password, $phone, $full_name, $managed_house_id);
        
        if ($insert->execute()) {
             echo json_encode(["status" => "success", "message" => "Đã tạo tài khoản Quản lý thành công. Nhân viên có thể đăng nhập bằng SĐT (Mật khẩu mặc định là SĐT)"]);
        } else {
             echo json_encode(["status" => "error", "message" => "Lỗi tạo tài khoản mới: " . $conn->error]);
        }
        $insert->close();
    }
    $stmt->close();
}
$conn->close();
?>
