<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With, ngrok-skip-browser-warning");

include __DIR__ . '/../../config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

$data = json_decode(file_get_contents("php://input"));

if(!isset($data->id) || !isset($data->status)) {
    echo json_encode(["status" => "error", "message" => "Thiếu dữ liệu"]);
    exit;
}

$id = (int)$data->id;
$status = $conn->real_escape_string($data->status);
$auth = qltro_auth_context($conn, $data);
$user_id = $auth["verified"] ? (int)$auth["user_id"] : 0;

// Bắt đầu transaction
$conn->begin_transaction();

try {
    // 1. Kiểm tra deposit tồn tại
    qltro_assert_can_access_table_row($conn, $auth, "deposits", $id, "Bạn không có quyền thao tác với phiếu cọc này");
    $check_sql = "SELECT room_id, status FROM deposits WHERE id = $id";
    $result = $conn->query($check_sql);
    if ($result->num_rows === 0) {
        throw new Exception("Phiếu cọc không tồn tại");
    }
    $row = $result->fetch_assoc();
    $room_id = $row['room_id'];
    $current_status = $row['status'];
    $reason = isset($data->reason) ? $conn->real_escape_string($data->reason) : '';

    $allowed_statuses = ['pending', 'completed', 'cancelled'];
    if (!in_array($status, $allowed_statuses, true)) {
        throw new Exception("Trạng thái phiếu cọc không hợp lệ");
    }

    if ($status !== $current_status && $current_status !== 'pending') {
         throw new Exception("Phiếu cọc đã khoá, không thể cập nhật");
    }

    if ($status === 'cancelled' && $current_status !== 'pending') {
        throw new Exception("Chỉ có thể hủy phiếu cọc đang chờ lập hợp đồng");
    }

    if ($status === 'completed' && $current_status !== 'pending') {
        throw new Exception("Chỉ có thể hoàn tất phiếu cọc đang chờ lập hợp đồng");
    }

    // 2. Cập nhật status của deposit
    $sql_update = "UPDATE deposits SET status = '$status' WHERE id = $id";
    if(!$conn->query($sql_update)) {
        throw new Exception("Lỗi khi cập nhật phiếu cọc: " . $conn->error);
    }

    // 3. Ghi Nhật ký (Deposit Audit Log)
    $log_stmt = $conn->prepare("INSERT INTO deposit_logs (deposit_id, user_id, old_status, new_status, reason) VALUES (?, ?, ?, ?, ?)");
    if ($log_stmt) {
        $log_stmt->bind_param("iisss", $id, $user_id, $current_status, $status, $reason);
        $log_stmt->execute();
        $log_stmt->close();
    }

    // 🔥 TỰ ĐỘNG TẠO PHIẾU CHI NẾU CÓ HOÀN TIỀN
    if ($status === 'cancelled') {
        $active_contract = $conn->query("SELECT id FROM contracts WHERE room_id = $room_id AND status = 'active' AND deleted_at IS NULL LIMIT 1")->fetch_assoc();
        $other_deposit = $conn->query("SELECT id FROM deposits WHERE room_id = $room_id AND id != $id AND status IN ('pending', 'waiting_payment') LIMIT 1")->fetch_assoc();

        if (!$active_contract && !$other_deposit) {
            $room_info = $conn->query("SELECT max_tenants FROM rooms WHERE id = $room_id")->fetch_assoc();
            $active_count = (int)($conn->query("SELECT COUNT(*) as total FROM tenants WHERE room_id = $room_id AND status = 'active' AND deleted_at IS NULL")->fetch_assoc()['total'] ?? 0);
            $max_tenants = (int)($room_info['max_tenants'] ?? 0);
            $new_room_status = ($active_count <= 0) ? 'empty' : (($active_count >= $max_tenants && $max_tenants > 0) ? 'full' : 'available');

            $sql_room = "UPDATE rooms SET status = '$new_room_status', current_tenants = $active_count WHERE id = $room_id";
            if(!$conn->query($sql_room)) {
                 throw new Exception("Lỗi cập nhật phòng: " . $conn->error);
            }
        }

        $refund_amount = isset($data->refund_amount) ? floatval($data->refund_amount) : 0;
        if ($refund_amount > 0) {
            $house_res = $conn->query("SELECT d.house_id, r.room_name, d.customer_name 
                                       FROM deposits d 
                                       JOIN rooms r ON d.room_id = r.id 
                                       WHERE d.id = $id");
            if ($house_res && $h_info = $house_res->fetch_assoc()) {
                $house_id = $h_info['house_id'];
                $room_name = $h_info['room_name'] ?? 'N/A';
                $cust_name = $h_info['customer_name'] ?? 'Khách thuê';
                $expense_desc = "Hoàn tiền cọc cho khách $cust_name (Phòng $room_name)";
                $expense_date = date('Y-m-d');

                $stmt_e = $conn->prepare("INSERT INTO expenses (house_id, room_id, receiver_name, amount, expense_date, expense_type, description) VALUES (?, ?, ?, ?, ?, 'refund', ?)");
                $stmt_e->bind_param("iisdss", $house_id, $room_id, $cust_name, $refund_amount, $expense_date, $expense_desc);
                $stmt_e->execute();
                $stmt_e->close();
            }
        }
    }

    // 🔥 TỰ ĐỘNG TẠO PHIẾU THU NẾU ĐẶT CỌC THÀNH CÔNG
    if ($status === 'completed') {
        $info_res = $conn->query("SELECT d.*, r.room_name FROM deposits d JOIN rooms r ON d.room_id = r.id WHERE d.id = $id");
        if ($info_res && $info = $info_res->fetch_assoc()) {
            $house_id = intval($info['house_id']);
            $amount = floatval($info['deposit_amount']);
            $cust_name = $info['customer_name'] ?? 'Khách thuê';
            $room_name = $info['room_name'] ?? 'N/A';
            $receipt_date = date('Y-m-d');
            $desc = "Thu tiền đặt cọc phòng $room_name - Khách: $cust_name";

            $cust_sql = $conn->real_escape_string($cust_name);
            $receipt_exists = $conn->query("SELECT id FROM receipts 
                                            WHERE house_id = $house_id 
                                              AND room_id = $room_id 
                                              AND receipt_type = 'deposit' 
                                              AND tenant_name = '$cust_sql'
                                              AND ABS(amount - $amount) < 0.01
                                            LIMIT 1")->fetch_assoc();
            if (!$receipt_exists) {
                $r_stmt = $conn->prepare("INSERT INTO receipts (house_id, room_id, tenant_name, amount, receipt_date, receipt_type, description) VALUES (?, ?, ?, ?, ?, 'deposit', ?)");
                if ($r_stmt) {
                    $r_stmt->bind_param("iisdss", $house_id, $room_id, $cust_name, $amount, $receipt_date, $desc);
                    $r_stmt->execute();
                    $r_stmt->close();
                }
            }
        }
    }

    // (Nếu completed thì Create Contract API sẽ lo việc đánh dấu room full hoặc DepositCompleted)

    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
