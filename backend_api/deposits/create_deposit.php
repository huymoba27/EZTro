<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, ngrok-skip-browser-warning");

include __DIR__ . '/../../config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
require_once dirname(__DIR__) . '/helpers/validation_helper.php';

$data = json_decode(file_get_contents("php://input"));

if(!isset($data->house_id) || !isset($data->room_id) || !isset($data->customer_name) || !isset($data->customer_phone) || !isset($data->deposit_amount) || !isset($data->deposit_date) || !isset($data->expected_move_in_date)) {
    echo json_encode(["status" => "error", "message" => "Thiếu dữ liệu"]);
    exit;
}

$house_id = (int)$data->house_id;
$room_id = (int)$data->room_id;
$auth = qltro_auth_context($conn, $data);
qltro_assert_can_access_house($conn, $auth, $house_id);
qltro_assert_can_access_room($conn, $auth, $room_id);
$customer_name = $conn->real_escape_string($data->customer_name);
$customer_phone = qltro_normalize_phone($data->customer_phone);
$deposit_amount = (float)$data->deposit_amount;
$deposit_date = $conn->real_escape_string($data->deposit_date);
$expected_move_in_date = $conn->real_escape_string($data->expected_move_in_date);
$note = isset($data->note) ? $conn->real_escape_string($data->note) : "";

// Bắt đầu transaction
$conn->begin_transaction();

try {
    $customer_phone = qltro_assert_valid_phone($customer_phone);
    if ($deposit_amount <= 0) {
        throw new Exception("Tiền cọc phải lớn hơn 0");
    }
    // 1. Kiểm tra phòng có phải là empty hoặc available không
    $check_room = $conn->query("SELECT status FROM rooms WHERE id = $room_id");
    if ($check_room->num_rows === 0) {
        throw new Exception("Phòng không tồn tại");
    }
    $room_row = $check_room->fetch_assoc();
    if ($room_row['status'] == 'full' || $room_row['status'] == 'deposited') {
        throw new Exception("Phòng đã được thuê hoặc đã có người cọc");
    }

    // 2. Insert vào bảng deposits
    if (qltro_active_tenant_phone_exists($conn, $customer_phone)) {
        throw new Exception("Số điện thoại này đã thuộc về khách thuê đang hoạt động.");
    }
    if (qltro_open_deposit_phone_exists($conn, $customer_phone)) {
        throw new Exception("Số điện thoại này đang có phiếu cọc chờ xử lý.");
    }

    $sql_insert = "INSERT INTO deposits (house_id, room_id, customer_name, customer_phone, deposit_amount, deposit_date, expected_move_in_date, note, status)
                   VALUES ($house_id, $room_id, '$customer_name', '$customer_phone', $deposit_amount, '$deposit_date', '$expected_move_in_date', '$note', 'pending')";
    
    if (!$conn->query($sql_insert)) {
        throw new Exception("Lỗi khi thêm phiếu cọc: " . $conn->error);
    }
    
    $deposit_id = $conn->insert_id;

    // 3. Update status phòng thành 'deposited'
    $sql_update_room = "UPDATE rooms SET status = 'deposited' WHERE id = $room_id";
    if (!$conn->query($sql_update_room)) {
        throw new Exception("Lỗi khi cập nhật trạng thái phòng: " . $conn->error);
    }

    // 3.1. TỰ ĐỘNG ĐÓNG BÀI ĐĂNG khi phòng đã cọc
    $conn->query("UPDATE posts SET status = 'closed' WHERE room_id = $room_id AND status = 'active'");

    // 4. 🔥 TỰ ĐỘNG TẠO PHIẾU THU
    $room_res = @$conn->query("SELECT room_name FROM rooms WHERE id = $room_id");
    $room_name = ($room_res && $row = $room_res->fetch_assoc()) ? $row['room_name'] : "N/A";
    
    $receipt_desc = "Thu tiền cọc giữ chỗ phòng $room_name";
    $sql_receipt = "INSERT INTO receipts (house_id, room_id, tenant_name, amount, receipt_date, receipt_type, description)
                    VALUES ($house_id, $room_id, '$customer_name', $deposit_amount, '$deposit_date', 'deposit', '$receipt_desc')";
    if (!$conn->query($sql_receipt)) {
        throw new Exception("Lỗi khi tạo phiếu thu tự động: " . $conn->error);
    }

    // 📝 GHI LOG TẠO PHIẾU CỌC
    $conn->query("INSERT INTO deposit_logs (deposit_id, user_id, old_status, new_status, reason) 
                  VALUES ($deposit_id, 0, NULL, 'pending', 'Tạo phiếu cọc mới - $customer_name - Phòng $room_id')");

    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Thêm phiếu cọc thành công", "deposit_id" => $deposit_id]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
