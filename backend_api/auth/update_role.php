<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user_id = $_POST['user_id'] ?? null;
    $role = $_POST['role'] ?? null;

    if (!$user_id || !$role) {
        echo json_encode(["status" => "error", "message" => "Thiếu thông tin User ID hoặc Role"]);
        exit;
    }

    if (!in_array($role, ['landlord', 'tenant'])) {
         echo json_encode(["status" => "error", "message" => "Role không hợp lệ. Chỉ chấp nhận 'landlord' hoặc 'tenant'"]);
         exit;
    }

    $stmt = $conn->prepare("UPDATE users SET role = ? WHERE id = ?");
    $stmt->bind_param("si", $role, $user_id);
    
    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Cập nhật vai trò thành công", "role" => $role]);
    } else {
        echo json_encode(["status" => "error", "message" => "Lỗi server: " . $conn->error]);
    }
    
    $stmt->close();
}
$conn->close();
?>
