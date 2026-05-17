<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, ngrok-skip-browser-warning");

include __DIR__ . '/../../config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
require_once dirname(__DIR__) . '/helpers/validation_helper.php';

$data = json_decode(file_get_contents("php://input"));

if (
    !isset($data->deposit_id) ||
    !isset($data->customer_name) ||
    !isset($data->customer_phone) ||
    !isset($data->deposit_amount) ||
    !isset($data->deposit_date) ||
    !isset($data->expected_move_in_date)
) {
    echo json_encode(["status" => "error", "message" => "Thiếu dữ liệu"]);
    exit;
}

$deposit_id = (int)$data->deposit_id;
$customer_name = trim((string)$data->customer_name);
$customer_phone = qltro_normalize_phone($data->customer_phone);
$deposit_amount = (float)$data->deposit_amount;
$deposit_date = trim((string)$data->deposit_date);
$expected_move_in_date = trim((string)$data->expected_move_in_date);
$note = isset($data->note) ? trim((string)$data->note) : "";
$auth = qltro_auth_context($conn, $data);
$user_id = $auth["verified"] ? (int)$auth["user_id"] : 0;

if ($deposit_id <= 0 || $customer_name === '' || $deposit_amount <= 0 || $deposit_date === '' || $expected_move_in_date === '') {
    echo json_encode(["status" => "error", "message" => "Dữ liệu phiếu cọc không hợp lệ"]);
    exit;
}

$conn->begin_transaction();

try {
    $customer_phone = qltro_assert_valid_phone($customer_phone);

    qltro_assert_can_access_table_row($conn, $auth, "deposits", $deposit_id, "Bạn không có quyền thao tác với phiếu cọc này");

    $stmt = $conn->prepare("SELECT house_id, room_id, customer_name, customer_phone, deposit_amount, status FROM deposits WHERE id = ? FOR UPDATE");
    $stmt->bind_param("i", $deposit_id);
    $stmt->execute();
    $current = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$current) {
        throw new Exception("Phiếu cọc không tồn tại");
    }
    if ($current['status'] !== 'pending') {
        throw new Exception("Chỉ có thể sửa phiếu cọc đang chờ lập hợp đồng");
    }

    if (qltro_active_tenant_phone_exists($conn, $customer_phone)) {
        throw new Exception("Số điện thoại này đã thuộc về khách thuê đang hoạt động.");
    }
    if (qltro_open_deposit_phone_exists($conn, $customer_phone, $deposit_id)) {
        throw new Exception("Số điện thoại này đang có phiếu cọc chờ xử lý.");
    }

    $update = $conn->prepare(
        "UPDATE deposits
         SET customer_name = ?, customer_phone = ?, deposit_amount = ?, deposit_date = ?, expected_move_in_date = ?, note = ?
         WHERE id = ?"
    );
    $update->bind_param(
        "ssdsssi",
        $customer_name,
        $customer_phone,
        $deposit_amount,
        $deposit_date,
        $expected_move_in_date,
        $note,
        $deposit_id
    );
    if (!$update->execute()) {
        throw new Exception("Lỗi khi cập nhật phiếu cọc: " . $update->error);
    }
    $update->close();

    $house_id = (int)$current['house_id'];
    $room_id = (int)$current['room_id'];
    $old_customer_name = (string)$current['customer_name'];
    $old_amount = (float)$current['deposit_amount'];
    $room_name = "N/A";
    $room_res = $conn->query("SELECT room_name FROM rooms WHERE id = $room_id");
    if ($room_res && $room_row = $room_res->fetch_assoc()) {
        $room_name = $room_row['room_name'] ?? "N/A";
    }
    $receipt_desc = "Thu tiền cọc giữ chỗ phòng $room_name";

    $receipt = $conn->prepare(
        "UPDATE receipts
         SET tenant_name = ?, amount = ?, receipt_date = ?, description = ?
         WHERE house_id = ?
           AND room_id = ?
           AND receipt_type = 'deposit'
           AND tenant_name = ?
           AND ABS(amount - ?) < 0.01"
    );
    $receipt->bind_param(
        "sdssiisd",
        $customer_name,
        $deposit_amount,
        $deposit_date,
        $receipt_desc,
        $house_id,
        $room_id,
        $old_customer_name,
        $old_amount
    );
    $receipt->execute();
    $receipt->close();

    $reason = "Cập nhật thông tin phiếu cọc";
    $log_stmt = $conn->prepare("INSERT INTO deposit_logs (deposit_id, user_id, old_status, new_status, reason) VALUES (?, ?, 'pending', 'pending', ?)");
    if ($log_stmt) {
        $log_stmt->bind_param("iis", $deposit_id, $user_id, $reason);
        $log_stmt->execute();
        $log_stmt->close();
    }

    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Cập nhật phiếu cọc thành công"]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
