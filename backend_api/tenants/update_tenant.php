<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
require_once dirname(__DIR__) . '/helpers/validation_helper.php';
header("Content-Type: application/json; charset=UTF-8");

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') throw new Exception("Phương thức không hợp lệ");

    $tenant_id     = intval($_POST['tenant_id']);
    $tenant_name   = $_POST['tenant_name'] ?? '';
    $phone         = qltro_normalize_phone($_POST['phone'] ?? '');
    $gender        = $_POST['gender'] ?? 'Nam';
    $birthday      = !empty($_POST['birthday']) ? $_POST['birthday'] : null;
    $id_card       = $_POST['id_card'] ?? '';
    $id_card_date  = !empty($_POST['id_card_date']) ? $_POST['id_card_date'] : null;
    $id_card_place = $_POST['id_card_place'] ?? '';
    $address       = $_POST['address'] ?? '';
    $email         = $_POST['email'] ?? '';

    if ($tenant_id <= 0 || empty($tenant_name)) throw new Exception("Dữ liệu không hợp lệ");

    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_tenant($conn, $auth, $tenant_id);
    $phone = qltro_assert_valid_phone($phone);

    if (qltro_active_tenant_phone_exists($conn, $phone, $tenant_id)) {
        throw new Exception("Số điện thoại này đã thuộc về khách thuê đang hoạt động.");
    }

    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/tenants/";
    
    // 1. Lấy thông tin ảnh cũ để giữ lại nếu không upload ảnh mới
    $res = $conn->query("SELECT user_id, cccd_front, cccd_back FROM tenants WHERE id = $tenant_id");
    $old_data = $res->fetch_assoc();
    $user_id = isset($old_data['user_id']) ? (int)$old_data['user_id'] : null;
    $cccd_front = $old_data['cccd_front'];
    $cccd_back = $old_data['cccd_back'];

    // 2. Xử lý ảnh mặt trước (nếu có gửi lên mới)
    if (isset($_FILES['cccd_front']) && $_FILES['cccd_front']['error'] == 0) {
        $cccd_front = time() . "_f_edit_" . $_FILES['cccd_front']['name'];
        move_uploaded_file($_FILES['cccd_front']['tmp_name'], $upload_dir . $cccd_front);
    }

    // 3. Xử lý ảnh mặt sau (nếu có gửi lên mới)
    if (isset($_FILES['cccd_back']) && $_FILES['cccd_back']['error'] == 0) {
        $cccd_back = time() . "_b_edit_" . $_FILES['cccd_back']['name'];
        move_uploaded_file($_FILES['cccd_back']['tmp_name'], $upload_dir . $cccd_back);
    }

    // 4. KIỂM TRA LIÊN KẾT TÀI KHOẢN MỚI (Nếu SĐT thay đổi hoặc chưa có liên kết)
    if (!empty($phone)) {
        $check_user = $conn->prepare("SELECT id FROM users WHERE phone = ? AND role IN ('tenant', 'unassigned') LIMIT 1");
        $check_user->bind_param("s", $phone);
        $check_user->execute();
        $res_user = $check_user->get_result();
        if ($res_user->num_rows > 0) {
            $user_id = $res_user->fetch_assoc()['id'];
            // Cập nhật role thành tenant nếu đang là unassigned
            $conn->query("UPDATE users SET role = 'tenant' WHERE id = $user_id AND role = 'unassigned'");
        }
        $check_user->close();
    }

    // 5. Thực hiện lệnh UPDATE
    $sql = "UPDATE tenants SET 
                user_id = ?,
                tenant_name = ?, 
                phone = ?, 
                gender = ?, 
                birthday = ?, 
                id_card = ?, 
                id_card_date = ?, 
                id_card_place = ?, 
                address = ?, 
                email = ?, 
                cccd_front = ?, 
                cccd_back = ? 
            WHERE id = ?";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("isssssssssssi", 
        $user_id, $tenant_name, $phone, $gender, $birthday, $id_card, 
        $id_card_date, $id_card_place, $address, $email, 
        $cccd_front, $cccd_back, $tenant_id
    );

    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Cập nhật thông tin thành công!"]);
    } else {
        throw new Exception("Lỗi Database: " . $stmt->error);
    }

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
