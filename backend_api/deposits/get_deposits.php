<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

// Các bộ lọc bổ sung
$deposit_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$room_id = isset($_GET['room_id']) ? (int)$_GET['room_id'] : 0;
$status = isset($_GET['status']) ? $conn->real_escape_string($_GET['status']) : '';
$month = isset($_GET['month']) ? (int)$_GET['month'] : 0;
$year = isset($_GET['year']) ? (int)$_GET['year'] : 0;

// 🎯 Cập nhật trạng thái cọc hết hạn (Nếu cần)
if ($user_id > 0 && $role === 'tenant') {
    $conn->query("UPDATE deposits SET status = 'expired' WHERE user_id = $user_id AND status = 'waiting_payment' AND payment_expires_at IS NOT NULL AND payment_expires_at < NOW()");
}

$sql = "SELECT d.*, h.house_name, r.room_name, r.deposit as room_deposit_amount
        FROM deposits d
        JOIN houses h ON d.house_id = h.id
        JOIN rooms r ON d.room_id = r.id
        WHERE 1=1 ";

// 1. PHÂN QUYỀN (LUÔN CÓ)
if ($role === 'admin') {
    // Admin thấy hết
} else if ($role === 'manager' && $managed_house_id > 0) {
    $sql .= " AND d.house_id = $managed_house_id ";
} else if ($role === 'tenant') {
    // Khách thuê: Thấy cọc của mình (qua user_id hoặc SĐT)
    $sql .= " AND (d.user_id = $user_id OR (d.user_id IS NULL AND d.customer_phone IN (SELECT phone FROM users WHERE id = $user_id))) ";
} else {
    // Chủ trọ (Landlord): Thấy cọc của các nhà mình sở hữu
    $sql .= " AND h.user_id = $user_id ";
}

// 2. BỘ LỌC CHI TIẾT (Nếu có truyền lên)
if ($deposit_id > 0) {
    $sql .= " AND d.id = $deposit_id ";
}
if ($house_id > 0) {
    $sql .= " AND d.house_id = $house_id ";
}
if ($room_id > 0) {
    $sql .= " AND d.room_id = $room_id ";
}
if ($status !== '' && $status !== 'all') {
    $sql .= " AND d.status = '$status' ";
}
if ($month > 0) {
    $sql .= " AND MONTH(d.deposit_date) = $month ";
}
if ($year > 0) {
    $sql .= " AND YEAR(d.deposit_date) = $year ";
}

$sql .= " ORDER BY d.id DESC";

$result = $conn->query($sql);
$data = [];

if ($result) {
    while ($row = $result->fetch_assoc()) {
        $data[] = $row;
    }
    
    // Nếu yêu cầu chi tiết (id cụ thể), trả về object thay vì array
    if ($deposit_id > 0 && count($data) > 0) {
        // Lấy Nhật ký phiếu cọc
        $logs = [];
        $log_sql = "SELECT l.*, u.full_name as user_name, u.role as user_role 
                    FROM deposit_logs l 
                    JOIN users u ON l.user_id = u.id 
                    WHERE l.deposit_id = $deposit_id 
                    ORDER BY l.created_at DESC";
        $l_res = $conn->query($log_sql);
        if ($l_res) {
            while($l_row = $l_res->fetch_assoc()) $logs[] = $l_row;
        }
        $data[0]['logs'] = $logs;

        echo json_encode(["status" => "success", "data" => $data[0]]);
    } else {
        echo json_encode(["status" => "success", "data" => $data]);
    }
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}
?>
