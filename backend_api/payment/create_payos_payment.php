<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

require_once dirname(__DIR__, 2) . '/vendor/autoload.php';
include dirname(__DIR__, 2) . '/config/config.php';
include dirname(__DIR__, 2) . '/config/payment_config.php';

use PayOS\PayOS;

$input = json_decode(file_get_contents('php://input'), true);
$invoice_id = isset($input['invoice_id']) ? intval($input['invoice_id']) : 0;
$user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
$role = $input['role'] ?? 'tenant';
$managed_house_id = isset($input['managed_house_id']) ? intval($input['managed_house_id']) : 0;

if ($invoice_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu invoice_id"]);
    exit;
}

// Lấy thông tin hóa đơn từ DB
$scope = "";
if ($role === 'tenant') {
    $scope = " AND (t.user_id = $user_id OR (t.user_id IS NULL AND t.status = 'active' AND t.deleted_at IS NULL AND t.phone IN (SELECT phone FROM users WHERE id = $user_id))) ";
} else if ($role === 'manager' && $managed_house_id > 0) {
    $scope = " AND h.id = $managed_house_id ";
} else if ($role !== 'admin') {
    $scope = " AND h.user_id = $user_id ";
}

$sql = "SELECT i.*, r.room_name, h.house_name 
        FROM invoices i 
        JOIN rooms r ON i.room_id = r.id 
        JOIN houses h ON r.house_id = h.id
        LEFT JOIN contracts c ON i.contract_id = c.id
        LEFT JOIN tenants t ON c.tenant_id = t.id
        WHERE i.id = ? $scope";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $invoice_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "Không tìm thấy hóa đơn hoặc bạn không có quyền thanh toán hóa đơn này"]);
    exit;
}

$invoice = $result->fetch_assoc();

if ($invoice['status'] === 'paid') {
    echo json_encode(["status" => "error", "message" => "Hóa đơn này đã được thanh toán"]);
    exit;
}

try {
    $payOS = new PayOS(PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY);

    // Mã đơn hàng: timestamp + invoice_id, tối đa 10 chữ số
    $orderCode = intval(substr(time(), -7) . str_pad($invoice_id, 3, '0', STR_PAD_LEFT));

    $amount = intval(floatval($invoice['total_amount']));
    if ($amount < 2000) $amount = 2000; // Min amount của PayOS

    // Mô tả tối đa 25 ký tự, không dấu
    $roomName = $invoice['room_name'] ?? $invoice_id;
    $description = "HD phong " . $roomName;
    $description = mb_substr(preg_replace('/[^\x00-\x7F]/', '', $description), 0, 25);

    $returnUrl = PUBLIC_BASE_URL . "/backend_api/payment/payos_return.php?invoice_id={$invoice_id}&success=true";
    $cancelUrl  = PUBLIC_BASE_URL . "/backend_api/payment/payos_return.php?invoice_id={$invoice_id}&success=false";

    $paymentData = [
        "orderCode"   => $orderCode,
        "amount"      => $amount,
        "description" => $description ?: "Hoa don #{$invoice_id}",
        "returnUrl"   => $returnUrl,
        "cancelUrl"   => $cancelUrl,
        "items"       => [
            [
                "name"     => "Tien phong va dich vu",
                "quantity" => 1,
                "price"    => $amount,
            ]
        ],
    ];

    $response = $payOS->createPaymentLink($paymentData);

    // Lưu orderCode vào DB để đối chiếu khi nhận webhook
    $oc = $conn->real_escape_string($orderCode);
    $conn->query("UPDATE invoices SET payos_order_code = '{$oc}' WHERE id = {$invoice_id}");

    echo json_encode([
        "status"      => "success",
        "checkoutUrl" => $response['checkoutUrl'],
        "orderCode"   => $orderCode,
        "qrCode"      => $response['qrCode'] ?? null,
        "bank_bin"    => $response['bin'] ?? null,
        "bank_account_number" => $response['accountNumber'] ?? null,
        "bank_account_name"   => $response['accountName'] ?? null,
        "payment_description" => $response['description'] ?? null,
    ]);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
