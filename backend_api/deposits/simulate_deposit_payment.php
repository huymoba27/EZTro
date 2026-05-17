<?php
// API: Giả lập thanh toán đặt cọc thành công (chỉ dùng để test)
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';

$appEnv = $_ENV['APP_ENV'] ?? getenv('APP_ENV') ?: 'production';
$paymentSimulationEnabled = filter_var(
    $_ENV['ENABLE_PAYMENT_SIMULATION'] ?? getenv('ENABLE_PAYMENT_SIMULATION') ?? false,
    FILTER_VALIDATE_BOOLEAN
);

if ($appEnv !== 'local' || !$paymentSimulationEnabled) {
    http_response_code(403);
    echo json_encode([
        "status" => "error",
        "message" => "Chuc nang gia lap thanh toan dang bi tat",
    ]);
    exit;
}

$deposit_id = isset($_GET['deposit_id']) ? (int)$_GET['deposit_id'] : 0;
if ($deposit_id <= 0) {
    $data = json_decode(file_get_contents("php://input"));
    $deposit_id = isset($data->deposit_id) ? (int)$data->deposit_id : 0;
}

if ($deposit_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu deposit_id"]);
    exit;
}

// Kiểm tra deposit tồn tại
$check = $conn->query("SELECT id, room_id, house_id, customer_name, deposit_amount, status FROM deposits WHERE id = $deposit_id");
if (!$check || $check->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Không tìm thấy đơn cọc"]);
    exit;
}

$deposit = $check->fetch_assoc();
// Chỉ chặn đơn đã thanh toán hoặc đã xác nhận hoàn thành
if (in_array($deposit['status'], ['pending', 'completed'])) {
    echo json_encode(["status" => "error", "message" => "Đơn cọc đã được thanh toán rồi (trạng thái: {$deposit['status']})"]);
    exit;
}

$room_id = intval($deposit['room_id']);
$house_id = intval($deposit['house_id']);
$amount = floatval($deposit['deposit_amount']);
$customer = $deposit['customer_name'];

$conn->begin_transaction();
try {
    // 1. Cập nhật trạng thái deposit → pending
    $conn->query("UPDATE deposits SET status = 'pending' WHERE id = $deposit_id");

    // 2. Cập nhật trạng thái phòng → deposited
    $conn->query("UPDATE rooms SET status = 'deposited' WHERE id = $room_id");

    // 2.1. TỰ ĐỘNG ĐÓNG BÀI ĐĂNG
    $conn->query("UPDATE posts SET status = 'closed' WHERE room_id = $room_id AND status = 'active'");

    // 3. Tạo phiếu thu
    $room_res = $conn->query("SELECT room_name FROM rooms WHERE id = $room_id");
    $room_name = ($room_res && $r = $room_res->fetch_assoc()) ? $r['room_name'] : "N/A";
    $receipt_desc = "Thu tiền cọc giữ chỗ phòng $room_name (Giả lập)";
    $receipt_date = date('Y-m-d');

    $r_stmt = $conn->prepare("INSERT INTO receipts (house_id, room_id, tenant_name, amount, receipt_date, receipt_type, description) VALUES (?, ?, ?, ?, ?, 'deposit', ?)");
    if ($r_stmt) {
        $r_stmt->bind_param("iisdss", $house_id, $room_id, $customer, $amount, $receipt_date, $receipt_desc);
        $r_stmt->execute();
        $r_stmt->close();
    }

    $conn->commit();
    echo json_encode([
        "status" => "success",
        "message" => "Giả lập thanh toán thành công! Đơn cọc #$deposit_id đã chuyển sang 'Đã thanh toán'",
        "deposit_status" => "pending"
    ]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
