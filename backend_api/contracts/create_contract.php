<?php
// 1. Cấu hình hệ thống
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

header("Content-Type: application/json; charset=UTF-8");

// 2. Kết nối Database
$configPath = $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
if (file_exists($configPath)) {
    include $configPath;
    require_once $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/backend_api/helpers/auth_guard.php';
    require_once $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/backend_api/helpers/validation_helper.php';
} else {
    echo json_encode(["status" => "error", "message" => "Không tìm thấy file config"]);
    exit;
}

try {
    // Bắt đầu giao dịch để đảm bảo an toàn dữ liệu
    $conn->begin_transaction();

    // 3. Nhận dữ liệu từ Flutter gửi lên
    $room_id       = isset($_POST['room_id']) ? intval($_POST['room_id']) : 0;
    $tenant_name   = trim($_POST['customer_name'] ?? '');
    $phone         = qltro_normalize_phone($_POST['customer_phone'] ?? '');
    
    // --- 🎯 VALIDATION ---
    if ($room_id <= 0 || empty($tenant_name) || empty($phone)) {
        throw new Exception("Vui lòng điền đầy đủ các thông tin bắt buộc (Tên khách, SĐT, Phòng)");
    }

    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_room($conn, $auth, $room_id);
    $phone = qltro_assert_valid_phone($phone);

    // Kiểm tra định dạng và độ dài SĐT (Việt Nam thường là 10 số)
    if (!qltro_is_valid_phone($phone)) {
        throw new Exception("Số điện thoại không hợp lệ (phải từ 10-11 chữ số)");
    }
    $email         = trim($_POST['email'] ?? '');
    $birthday      = !empty($_POST['birthday']) ? $_POST['birthday'] : null; 
    $gender        = $_POST['gender'] ?? 'Nam';
    $id_card       = trim($_POST['id_card'] ?? '');
    $id_card_date  = !empty($_POST['id_card_date']) ? $_POST['id_card_date'] : null;
    $id_card_place = trim($_POST['id_card_place'] ?? '');
    $address       = trim($_POST['address'] ?? '');
    $start_date    = $_POST['start_date'] ?? date('Y-m-d');
    $end_date      = !empty($_POST['end_date']) ? $_POST['end_date'] : null;
    $created_at    = date('Y-m-d H:i:s'); 
    $price         = isset($_POST['rent_price']) ? doubleval($_POST['rent_price']) : 0;
    $deposit       = isset($_POST['deposit_amount']) ? doubleval($_POST['deposit_amount']) : 0;
    $payment_day   = isset($_POST['payment_day']) ? intval($_POST['payment_day']) : 5;
    $start_electric = isset($_POST['start_electric']) ? intval($_POST['start_electric']) : 0;
    $start_water    = isset($_POST['start_water']) ? intval($_POST['start_water']) : 0;

    if (qltro_active_tenant_phone_exists($conn, $phone)) {
        throw new Exception("Số điện thoại này đã thuộc về khách thuê đang hoạt động.");
    }
    $deposit_id = isset($_POST['deposit_id']) ? intval($_POST['deposit_id']) : 0;
    if (qltro_open_deposit_phone_exists($conn, $phone, $deposit_id)) {
        throw new Exception("Số điện thoại này đang có phiếu cọc chờ xử lý.");
    }

    // --- 🎯 VALIDATION ---
    if ($room_id <= 0 || empty($tenant_name) || empty($phone) || $price <= 0) {
        throw new Exception("Vui lòng điền đầy đủ các thông tin bắt buộc (Tên khách, SĐT, Phòng, Giá thuê)");
    }
    if ($deposit < 0) {
        throw new Exception("Tiền cọc không được âm");
    }
    if ($payment_day < 1 || $payment_day > 31) {
        throw new Exception("Ngày thu tiền phải nằm trong khoảng 1-31");
    }
    if ($start_electric < 0 || $start_water < 0) {
        throw new Exception("Chỉ số điện nước đầu kỳ không được âm");
    }

    // Kiểm tra trạng thái phòng
    $check_room = $conn->query("SELECT status FROM rooms WHERE id = $room_id");
    if ($check_room->num_rows === 0) throw new Exception("Phòng không tồn tại");
    $room_status = $check_room->fetch_assoc()['status'];
    if ($deposit_id > 0) {
        qltro_assert_can_access_table_row($conn, $auth, "deposits", $deposit_id, "Bạn không có quyền thao tác với phiếu cọc này");
        $deposit_stmt = $conn->prepare("SELECT room_id, status, customer_phone FROM deposits WHERE id = ? FOR UPDATE");
        $deposit_stmt->bind_param("i", $deposit_id);
        $deposit_stmt->execute();
        $deposit_row = $deposit_stmt->get_result()->fetch_assoc();
        $deposit_stmt->close();

        if (!$deposit_row) {
            throw new Exception("Phiếu cọc không tồn tại");
        }
        if ((int)$deposit_row['room_id'] !== $room_id) {
            throw new Exception("Phiếu cọc chỉ được dùng để ký hợp đồng đúng phòng đã cọc.");
        }
        if ($deposit_row['status'] !== 'pending') {
            throw new Exception("Chỉ có thể lập hợp đồng từ phiếu cọc đang chờ lập hợp đồng.");
        }
        if (qltro_normalize_phone($deposit_row['customer_phone'] ?? '') !== $phone) {
            throw new Exception("Số điện thoại trên hợp đồng không khớp với phiếu cọc.");
        }
    }
    if ($room_status === 'full') throw new Exception("Phòng đã đầy, không thể tạo thêm hợp đồng");

    // Kiểm tra trùng hợp đồng (cùng khách, cùng phòng, đang active)
    $active_contract = $conn->query("SELECT id FROM contracts WHERE room_id = $room_id AND status = 'active' LIMIT 1");
    if ($active_contract && $active_contract->num_rows > 0) {
        throw new Exception("Phong nay dang co hop dong hoat dong. Vui long thanh ly truoc khi ky hop dong moi.");
    }

    $check_dup = $conn->query("SELECT id FROM contracts WHERE room_id = $room_id AND tenant_id IN (SELECT id FROM tenants WHERE phone = '$phone' AND status = 'active') AND status = 'active'");
    if ($check_dup->num_rows > 0) throw new Exception("Khách thuê này đã có hợp đồng đang hoạt động tại phòng này");

    // Kiểm tra ngày
    if ($end_date && strtotime($end_date) <= strtotime($start_date)) {
        throw new Exception("Ngày kết thúc hợp đồng phải sau ngày bắt đầu");
    }
    
    // Nhận danh sách dịch vụ
    $service_ids = isset($_POST['service_ids']) ? $_POST['service_ids'] : [];
    if (!is_array($service_ids)) {
        $service_ids = json_decode($service_ids, true) ?: [];
    }

    // 4. Hàm xử lý Upload ảnh CCCD
    function uploadImage($fileKey, $prefix) {
        if (isset($_FILES[$fileKey]) && $_FILES[$fileKey]['error'] == 0) {
            $target_dir = "../../uploads/cccd/";
            if (!file_exists($target_dir)) mkdir($target_dir, 0777, true);
            
            $extension = pathinfo($_FILES[$fileKey]["name"], PATHINFO_EXTENSION);
            $file_name = $prefix . "_" . time() . "_" . uniqid() . "." . $extension;
            if (move_uploaded_file($_FILES[$fileKey]["tmp_name"], $target_dir . $file_name)) {
                return $file_name;
            }
        }
        return null;
    }

    $cccd_front = uploadImage('cccd_front', 'front');
    $cccd_back  = uploadImage('cccd_back', 'back');

    // 5. XỬ LÝ LIÊN KẾT TÀI KHOẢN (Đồng bộ bảng tenants và users)
    // Kiểm tra xem SĐT này đã có tài khoản user chưa
    $user_id = null;
    $check_user = $conn->prepare("SELECT id FROM users WHERE phone = ? AND role IN ('tenant', 'unassigned') LIMIT 1");
    $check_user->bind_param("s", $phone);
    $check_user->execute();
    $res_user = $check_user->get_result();
    
    if ($res_user->num_rows > 0) {
        $user_data = $res_user->fetch_assoc();
        $user_id = $user_data['id'];
        // Cập nhật role thành tenant nếu đang là unassigned
        $conn->query("UPDATE users SET role = 'tenant' WHERE id = $user_id AND role = 'unassigned'");
    }
    // 🎯 LƯU Ý: Không tự động tạo tài khoản ở đây nữa. 
    // Khách thuê sẽ tự đăng ký tài khoản sau, và register.php sẽ tự liên kết qua SĐT.
    $check_user->close();

    // 6. CHÈN VÀO BẢNG TENANTS
    $sql1 = "INSERT INTO tenants (user_id, room_id, tenant_name, phone, email, birthday, gender, id_card, id_card_date, id_card_place, address, join_date, cccd_front, cccd_back, status, is_representative) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', 1)";

    $stmt1 = $conn->prepare($sql1);
    $stmt1->bind_param("iissssssssssss", 
        $user_id, $room_id, $tenant_name, $phone, $email, $birthday, $gender, 
        $id_card, $id_card_date, $id_card_place, $address, 
        $start_date, $cccd_front, $cccd_back
    );
    $stmt1->execute();
    $tenant_record_id = $stmt1->insert_id; // Đây mới là ID thực sự của khách thuê trong bảng tenants

    // 7. CHÈN VÀO BẢNG CONTRACTS (Sử dụng $tenant_record_id từ bảng tenants để JOIN chính xác)
    $sql2 = "INSERT INTO contracts (room_id, tenant_id, start_date, end_date, rent_price, deposit_amount, payment_day, start_electric_index, start_water_index, status, created_at) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', ?)";
    $stmt2 = $conn->prepare($sql2);
    $stmt2->bind_param("iissddiiis", 
        $room_id, $tenant_record_id, $start_date, $end_date, $price, $deposit, $payment_day, $start_electric, $start_water, $created_at
    );
    $stmt2->execute();
    $contract_id = $stmt2->insert_id;

    // 🎯 CẬP NHẬT TRẠNG THÁI PHIẾU CỌC (Nếu có)
    if ($deposit_id > 0) {
        $conn->query("UPDATE deposits SET status = 'completed' WHERE id = $deposit_id");
    }

    // 7. LƯU DỊCH VỤ CHI TIẾT
    if (!empty($service_ids)) {
        $sql_get_svc = "SELECT service_name, price, unit, charge_type FROM services WHERE id = ?";
        $stmt_get_svc = $conn->prepare($sql_get_svc);

        $sql_ins_svc = "INSERT INTO contract_services (contract_id, service_id, service_name, service_price, unit, charge_type) VALUES (?, ?, ?, ?, ?, ?)";
        $stmt_ins_svc = $conn->prepare($sql_ins_svc);

        foreach ($service_ids as $s_id) {
            $stmt_get_svc->bind_param("i", $s_id);
            $stmt_get_svc->execute();
            $svc_data = $stmt_get_svc->get_result()->fetch_assoc();

            if ($svc_data) {
                $stmt_ins_svc->bind_param("iisdss", 
                    $contract_id, 
                    $s_id,
                    $svc_data['service_name'], 
                    $svc_data['price'], 
                    $svc_data['unit'],
                    $svc_data['charge_type']
                );
                $stmt_ins_svc->execute();
            }
        }
    }

    // 8. CẬP NHẬT SỐ NGƯỜI & TRẠNG THÁI PHÒNG
    $res_info = $conn->query("SELECT max_tenants FROM rooms WHERE id = $room_id");
    $row_info = $res_info->fetch_assoc();
    $max_tenants = (int)($row_info['max_tenants'] ?? 0);

    $res_count = $conn->query("SELECT COUNT(*) as total FROM tenants WHERE room_id = $room_id AND status = 'active'");
    $row_count = $res_count->fetch_assoc();
    $current_count = (int)$row_count['total'];

    // Trạng thái mới: Nếu số người >= số người tối đa -> full, ngược lại -> available
    $new_status = ($current_count >= $max_tenants && $max_tenants > 0) ? 'full' : 'available';
    $conn->query("UPDATE rooms SET current_tenants = $current_count, status = '$new_status' WHERE id = $room_id");

    // 8.1. TỰ ĐỘNG ĐÓNG BÀI ĐĂNG khi phòng đã có người thuê
    $conn->query("UPDATE posts SET status = 'closed' WHERE room_id = $room_id AND status = 'active'");

    // 9. 🔥 TỰ ĐỘNG TẠO PHIẾU THU (CHỈ KHI KÝ TRỰC TIẾP - KHÔNG QUA ĐẶT CỌ TRƯỚC)
    if ($deposit_id == 0 && $deposit > 0) {
        $house_res = $conn->query("SELECT house_id, room_name FROM rooms WHERE id = $room_id");
        if ($house_res && $house_info = $house_res->fetch_assoc()) {
            $house_id = $house_info['house_id'];
            $room_name = $house_info['room_name'];
            $receipt_desc = "Thu tiền cọc khi ký hợp đồng phòng $room_name";
            $receipt_date = date('Y-m-d');

            $stmt_r = $conn->prepare("INSERT INTO receipts (house_id, room_id, tenant_name, amount, receipt_date, receipt_type, description) VALUES (?, ?, ?, ?, ?, 'deposit', ?)");
            $stmt_r->bind_param("iisdss", $house_id, $room_id, $tenant_name, $deposit, $receipt_date, $receipt_desc);
            $stmt_r->execute();
            $stmt_r->close();
        }
    }

    // 10. GHI LOG TẠO HỢP ĐỒNG
    $conn->query("INSERT INTO contract_logs (contract_id, user_id, action, old_status, new_status, reason) 
                  VALUES ($contract_id, " . (isset($_POST['user_id']) ? intval($_POST['user_id']) : 0) . ", 'create', NULL, 'active', 'Ký hợp đồng mới')");

    // 11. GHI LOG KHÁCH THUÊ
    $conn->query("INSERT INTO tenant_logs (tenant_id, user_id, action, old_status, new_status, reason) 
                  VALUES ($tenant_record_id, " . (isset($_POST['user_id']) ? intval($_POST['user_id']) : 0) . ", 'create', NULL, 'active', 'Thêm khách thuê khi ký HĐ')");

    // Hoàn tất giao dịch
    $conn->commit();
    echo json_encode([
        "status" => "success", 
        "message" => "Hợp đồng đã được ký kết thành công!",
        "data" => [
            "id" => $contract_id,
            "tenant_id" => $user_id
        ]
    ]);

} catch (Exception $e) {
    if(isset($conn)) $conn->rollback();
    error_log($e->getMessage());
    echo json_encode(["status" => "error", "message" => "Lỗi: " . $e->getMessage()]);
}
?>
