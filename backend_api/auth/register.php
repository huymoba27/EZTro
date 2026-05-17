<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/backend_api/helpers/validation_helper.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    $full_name = $_POST['full_name'] ?? '';
    $phone = qltro_normalize_phone($_POST['phone'] ?? '');

    if (empty($username) || empty($password)) {
        echo json_encode(["status" => "error", "message" => "Vui lòng nhập tên tài khoản và mật khẩu"]);
        exit;
    }

    // Kiểm tra xem username hoặc phone đã tồn tại chưa
    if (!empty($phone) && !qltro_is_valid_phone($phone)) {
        echo json_encode(["status" => "error", "message" => "Số điện thoại không hợp lệ. Vui lòng nhập 10-11 chữ số và bắt đầu bằng 0."]);
        exit;
    }

    $stmt_check = $conn->prepare("SELECT id FROM users WHERE username = ? OR (phone = ? AND phone != '')");
    $stmt_check->bind_param("ss", $username, $phone);
    $stmt_check->execute();
    $res_check = $stmt_check->get_result();

    if ($res_check->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "Tên tài khoản hoặc số điện thoại đã tồn tại!"]);
        $stmt_check->close();
        exit;
    }
    $stmt_check->close();

    // Thêm user mới
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    $role = 'unassigned'; // Mặc định chưa có vai trò

    // 🎯 KIỂM TRA XEM CÓ PHẢI LÀ KHÁCH THUÊ ĐÃ ĐƯỢC CHỦ NHÀ THÊM TRƯỚC KHÔNG
    $is_existing_tenant = false;
    $matched_tenant_id = 0;
    if (!empty($phone)) {
        $stmt_tenant = $conn->prepare("SELECT id FROM tenants WHERE phone = ? AND (user_id IS NULL OR user_id = 0) AND status = 'active' AND deleted_at IS NULL ORDER BY id DESC LIMIT 1");
        $stmt_tenant->bind_param("s", $phone);
        $stmt_tenant->execute();
        $res_tenant = $stmt_tenant->get_result();
        if ($res_tenant->num_rows > 0) {
            $role = 'tenant'; // 🎯 Tự động gán vai trò là khách thuê
            $is_existing_tenant = true;
            $matched_tenant_id = (int)$res_tenant->fetch_assoc()['id'];
        }
        $stmt_tenant->close();
    }

    $stmt = $conn->prepare("INSERT INTO users (username, password, full_name, phone, role) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("sssss", $username, $hashed_password, $full_name, $phone, $role);
    
    if ($stmt->execute()) {
        $user_id = $conn->insert_id;
        $room_id = null;
        $is_renting = false;
        $display_name = $full_name;

        // 🎯 NẾU LÀ KHÁCH THUÊ CŨ, CẬP NHẬT LIÊN KẾT USER_ID VÀ LẤY THÊM THÔNG TIN
        if ($is_existing_tenant) {
            $stmt_link = $conn->prepare("UPDATE tenants SET user_id = ? WHERE id = ? AND (user_id IS NULL OR user_id = 0)");
            $stmt_link->bind_param("ii", $user_id, $matched_tenant_id);
            $stmt_link->execute();
            $stmt_link->close();

            // Lấy thông tin phòng để App hiển thị menu ngay
            $stmt_info = $conn->prepare("SELECT room_id, tenant_name FROM tenants WHERE id = ? AND status = 'active' LIMIT 1");
            $stmt_info->bind_param("i", $matched_tenant_id);
            $stmt_info->execute();
            $res_info = $stmt_info->get_result();
            if ($res_info->num_rows > 0) {
                $tenant_data = $res_info->fetch_assoc();
                $room_id = $tenant_data['room_id'] ? intval($tenant_data['room_id']) : null;
                $is_renting = $room_id !== null;
                if (!empty($tenant_data['tenant_name'])) {
                    $display_name = $tenant_data['tenant_name'];
                }
            }
            $stmt_info->close();
        }

        echo json_encode([
            "status" => "success", 
            "message" => "Đăng ký thành công" . ($is_existing_tenant ? " và đã liên kết với dữ liệu thuê phòng" : ""),
            "user_id" => $user_id,
            "username" => $username,
            "role" => $role,
            "full_name" => $display_name, // 🎯 Trả về tên khách thuê nếu có
            "phone" => $phone,
            "is_renting" => $is_renting,
            "room_id" => $room_id
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Lỗi server: " . $conn->error]);
    }
    $stmt->close();
}
$conn->close();
?>
