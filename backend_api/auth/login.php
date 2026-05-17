<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/backend_api/helpers/validation_helper.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user = $_POST['username'] ?? '';
    $pass = $_POST['password'] ?? '';

    if (empty($user) || empty($pass)) {
        echo json_encode(["status" => "error", "message" => "Vui lòng nhập tài khoản và mật khẩu"]);
        exit;
    }

    // 1. Kiểm tra trong bảng users (Bao gồm cả Landlord, Manager và Tenant)
    $stmt = $conn->prepare("SELECT id, username, password, role, full_name, managed_house_id, phone FROM users WHERE username = ? OR phone = ?");
    $stmt->bind_param("ss", $user, $user);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $row['phone'] = qltro_normalize_phone($row['phone'] ?? '');
        $user_id = intval($row['id']);
        
        // Kiểm tra mật khẩu (hỗ trợ cả mật khẩu hash và mật khẩu cũ)
        $is_password_valid = false;
        if (password_verify($pass, $row['password'])) {
            $is_password_valid = true;
        } else if ($pass === $row['password']) {
            $is_password_valid = true;
            // Tự động nâng cấp mật khẩu sang dạng mã hóa
            $new_hash = password_hash($pass, PASSWORD_DEFAULT);
            $stmt_update = $conn->prepare("UPDATE users SET password = ? WHERE id = ?");
            $stmt_update->bind_param("si", $new_hash, $user_id);
            $stmt_update->execute();
        }

        if ($is_password_valid) {
            // Lấy thông tin phòng nếu là khách thuê (Truy vấn qua user_id đã được liên kết)
            $is_renting = false;
            $room_id = null;
            $display_name = $row['full_name']; // Mặc định dùng tên ở bảng users

            if (!empty($row['phone']) && in_array($row['role'], ['tenant', 'unassigned'], true)) {
                $stmt_link = $conn->prepare("SELECT id FROM tenants WHERE phone = ? AND (user_id IS NULL OR user_id = 0) AND status = 'active' AND deleted_at IS NULL ORDER BY id DESC LIMIT 1");
                $stmt_link->bind_param("s", $row['phone']);
                $stmt_link->execute();
                $res_link = $stmt_link->get_result();
                if ($res_link->num_rows > 0) {
                    $tenant_link_id = (int)$res_link->fetch_assoc()['id'];
                    $stmt_update_tenant = $conn->prepare("UPDATE tenants SET user_id = ? WHERE id = ? AND (user_id IS NULL OR user_id = 0)");
                    $stmt_update_tenant->bind_param("ii", $user_id, $tenant_link_id);
                    $stmt_update_tenant->execute();
                    $stmt_update_tenant->close();
                    $conn->query("UPDATE users SET role = 'tenant' WHERE id = $user_id AND role = 'unassigned'");
                    $row['role'] = $row['role'] === 'unassigned' ? 'tenant' : $row['role'];
                }
                $stmt_link->close();
            }
            
            $stmt_check = $conn->prepare("SELECT room_id, tenant_name FROM tenants WHERE user_id = ? AND status = 'active' LIMIT 1");
            $stmt_check->bind_param("i", $user_id);
            $stmt_check->execute();
            $res_check = $stmt_check->get_result();
            if ($res_check->num_rows > 0) {
                $tenant_data = $res_check->fetch_assoc();
                $is_renting = $tenant_data['room_id'] !== null;
                $room_id = $tenant_data['room_id'] ? intval($tenant_data['room_id']) : null;
                
                // 🎯 ƯU TIÊN LẤY TÊN TỪ BẢNG TENANTS NẾU CÓ
                if (!empty($tenant_data['tenant_name'])) {
                    $display_name = $tenant_data['tenant_name'];
                }
            }
            $stmt_check->close();

            echo json_encode([
                "status" => "success",
                "user_id" => $user_id,
                "username" => $row['username'],
                "role" => $row['role'],
                "managed_house_id" => $row['managed_house_id'] ? intval($row['managed_house_id']) : null,
                "full_name" => $display_name, // 🎯 Trả về tên đã được ưu tiên
                "phone" => $row['phone'],
                "is_renting" => $is_renting,
                "room_id" => $room_id
            ]);
            $stmt->close();
            exit;
        }
    }
    $stmt->close();

    echo json_encode(["status" => "error", "message" => "Tên đăng nhập hoặc mật khẩu không chính xác!"]);
}
?>
