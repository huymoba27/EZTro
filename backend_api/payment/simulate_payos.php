<?php
// Script này dùng để giả lập việc PayOS thanh toán thành công
header("Content-Type: application/json; charset=UTF-8");

include dirname(__DIR__, 2) . '/config/config.php';

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

// Nhận invoice_id từ App
$input = json_decode(file_get_contents('php://input'), true);
$invoice_id = isset($input['invoice_id']) ? intval($input['invoice_id']) : 0;

if ($invoice_id <= 0) {
    // Fallback cho GET request nếu cần test trình duyệt
    $invoice_id = isset($_GET['invoice_id']) ? intval($_GET['invoice_id']) : 0;
}

if ($invoice_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu invoice_id"]);
    exit;
}

// 1. Lấy orderCode và số tiền từ DB
$sql = "SELECT payos_order_code, total_amount FROM invoices WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $invoice_id);
$stmt->execute();
$res = $stmt->get_result();

if ($res->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Hóa đơn không tồn tại"]);
    exit;
}

$invoice = $res->fetch_assoc();
$orderCode = $invoice['payos_order_code'];

if (!$orderCode) {
    echo json_encode(["status" => "error", "message" => "Hóa đơn chưa có mã thanh toán PayOS"]);
    exit;
}

// 2. Tạo Payload giả lập
$payload = json_encode([
    "code" => "00",
    "desc" => "success",
    "data" => [
        "orderCode" => intval($orderCode),
        "amount" => intval($invoice['total_amount']),
        "description" => "Gia lap thanh toan Flutter",
        "reference" => "SIM_" . time(),
        "transactionDateTime" => date("Y-m-d H:i:s"),
        "code" => "00",
        "desc" => "Thanh cong"
    ],
    "signature" => "SIMULATED_SIGNATURE"
]);

// 3. Gọi Webhook qua LOCALHOST (Tránh lỗi ngrok loopback)
$webhook_local_url = "http://localhost/ql_tro/backend_api/payment/payos_webhook.php";

$ch = curl_init($webhook_local_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);

$response = curl_exec($ch);
$err = curl_error($ch);
curl_close($ch);

if ($err) {
    echo json_encode(["status" => "error", "message" => "Lỗi gọi Webhook nội bộ: $err"]);
} else {
    // Trả về kết quả từ Webhook cho App
    echo $response;
}
?>
