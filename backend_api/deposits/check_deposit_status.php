<?php
// API: Kiểm tra trạng thái đơn đặt cọc (polling từ app)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';

$deposit_id = isset($_GET['deposit_id']) ? (int)$_GET['deposit_id'] : 0;

if ($deposit_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu deposit_id"]);
    exit;
}

// Kiểm tra và auto-expire nếu quá hạn
$check = $conn->query("SELECT * FROM deposits WHERE id = $deposit_id");
if (!$check || $check->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Không tìm thấy đơn cọc"]);
    exit;
}

$deposit = $check->fetch_assoc();

// Nếu đang waiting_payment và đã quá hạn → tự chuyển thành expired (dùng MySQL NOW() để đúng timezone)
if ($deposit['status'] === 'waiting_payment' && $deposit['payment_expires_at'] !== null) {
    $expire_check = $conn->query("SELECT NOW() > '$deposit[payment_expires_at]' as is_expired");
    $is_expired = ($expire_check && $row = $expire_check->fetch_assoc()) ? $row['is_expired'] : 0;
    if ($is_expired) {
        $conn->query("UPDATE deposits SET status = 'expired' WHERE id = $deposit_id AND status = 'waiting_payment'");
        $deposit['status'] = 'expired';
    }
}

echo json_encode([
    "status" => "success",
    "data" => [
        "deposit_id"         => (int)$deposit['id'],
        "deposit_status"     => $deposit['status'],
        "payment_expires_at" => $deposit['payment_expires_at'],
        "payos_order_code"   => $deposit['payos_order_code'],
        "deposit_amount"     => $deposit['deposit_amount'],
    ]
]);
?>
