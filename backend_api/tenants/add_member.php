<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
require_once dirname(__DIR__) . '/helpers/validation_helper.php';
header("Content-Type: application/json; charset=UTF-8");

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') throw new Exception("Phương thức không hợp lệ");

    $room_id       = intval($_POST['room_id']);
    $tenant_name   = $_POST['tenant_name'] ?? '';
    $phone         = qltro_normalize_phone($_POST['phone'] ?? '');
    $gender        = $_POST['gender'] ?? 'Nam';
    
    // Nhận thêm Ngày sinh từ Flutter
    $birthday      = !empty($_POST['birthday']) ? $_POST['birthday'] : null; 
    
    $id_card       = $_POST['id_card'] ?? '';
    $address       = $_POST['address'] ?? '';
    $email         = $_POST['email'] ?? '';
    $id_card_date  = !empty($_POST['id_card_date']) ? $_POST['id_card_date'] : null;
    $id_card_place = $_POST['id_card_place'] ?? '';
    $join_date     = date('Y-m-d');

    if ($room_id <= 0 || empty($tenant_name)) throw new Exception("Thông tin không đầy đủ");

    // Xử lý upload ảnh
    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_room($conn, $auth, $room_id);
    $phone = qltro_assert_valid_phone($phone);

    if (qltro_active_tenant_phone_exists($conn, $phone)) {
        throw new Exception("Số điện thoại này đã thuộc về khách thuê đang hoạt động.");
    }

    $cccd_front_name = "";
    $cccd_back_name  = "";
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/tenants/";
    if (!is_dir($upload_dir)) mkdir($upload_dir, 0777, true);

    if (isset($_FILES['cccd_front']) && $_FILES['cccd_front']['error'] == 0) {
        $cccd_front_name = time() . "_f_" . $_FILES['cccd_front']['name'];
        move_uploaded_file($_FILES['cccd_front']['tmp_name'], $upload_dir . $cccd_front_name);
    }
    if (isset($_FILES['cccd_back']) && $_FILES['cccd_back']['error'] == 0) {
        $cccd_back_name = time() . "_b_" . $_FILES['cccd_back']['name'];
        move_uploaded_file($_FILES['cccd_back']['tmp_name'], $upload_dir . $cccd_back_name);
    }

    $conn->begin_transaction();

    // 🎯 KIỂM TRA LIÊN KẾT TÀI KHOẢN (Nếu SĐT đã đăng ký user)
    $user_id = null;
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

    // 1. Insert (Bổ sung cột user_id)
    $sql_insert = "INSERT INTO tenants (user_id, room_id, tenant_name, phone, gender, birthday, id_card, id_card_date, id_card_place, address, email, cccd_front, cccd_back, join_date, status, is_representative) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 0)";
    
    $stmt = $conn->prepare($sql_insert);
    
    // Chuỗi định dạng: "iissssssssssss" (Bổ sung 'i' cho user_id ở đầu)
    $stmt->bind_param("iissssssssssss", 
        $user_id, $room_id, $tenant_name, $phone, $gender, $birthday, 
        $id_card, $id_card_date, $id_card_place, $address, 
        $email, $cccd_front_name, $cccd_back_name, $join_date
    );
    
    if (!$stmt->execute()) {
        throw new Exception("Lỗi khi lưu dữ liệu: " . $stmt->error);
    }

    // 2. Cập nhật số người trong phòng
    $conn->query("UPDATE rooms SET current_tenants = current_tenants + 1 WHERE id = $room_id");
    
    // 3. Tự động set full nếu đạt giới hạn
    $conn->query("UPDATE rooms SET status = 'full' WHERE id = $room_id AND current_tenants >= max_tenants");

    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Thêm thành viên thành công!"]);

} catch (Exception $e) {
    if(isset($conn)) $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
