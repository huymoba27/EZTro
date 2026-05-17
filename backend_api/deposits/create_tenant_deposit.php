<?php
// API: Khách thuê tạo đơn đặt cọc + tạo link thanh toán PayOS
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning");

require_once dirname(__DIR__, 2) . '/vendor/autoload.php';
include dirname(__DIR__, 2) . '/config/config.php';
include dirname(__DIR__, 2) . '/config/payment_config.php';
require_once dirname(__DIR__) . '/helpers/validation_helper.php';

use PayOS\PayOS;

$data = json_decode(file_get_contents("php://input"));

// Validate input
$required = ['user_id', 'room_id', 'house_id', 'customer_name', 'customer_phone'];
foreach ($required as $field) {
    if (!isset($data->$field) || empty($data->$field)) {
        echo json_encode(["status" => "error", "message" => "Thiếu trường: $field"]);
        exit;
    }
}

$user_id = (int)$data->user_id;
$room_id = (int)$data->room_id;
$house_id = (int)$data->house_id;
$post_id = isset($data->post_id) ? (int)$data->post_id : null;
$customer_name = $conn->real_escape_string($data->customer_name);
$customer_phone = qltro_normalize_phone($data->customer_phone);
$note = isset($data->note) ? $conn->real_escape_string($data->note) : "Đặt cọc trực tuyến";

$conn->begin_transaction();

try {
    $customer_phone = qltro_assert_valid_phone($customer_phone);
    // 1. Kiểm tra phòng có trống không
    $check_room = $conn->query("SELECT r.status, r.deposit, r.room_name, h.house_name 
                                FROM rooms r 
                                JOIN houses h ON r.house_id = h.id 
                                WHERE r.id = $room_id");
    if ($check_room->num_rows === 0) {
        throw new Exception("Phòng không tồn tại");
    }
    $room = $check_room->fetch_assoc();
    if ($room['status'] == 'full' || $room['status'] == 'deposited') {
        throw new Exception("Phòng đã được thuê hoặc đã có người cọc");
    }

    // 2. Kiểm tra user đã có đơn cọc pending cho phòng này chưa
    $check_dup = $conn->query("SELECT id FROM deposits WHERE user_id = $user_id AND room_id = $room_id AND status IN ('waiting_payment', 'pending')");
    if ($check_dup && $check_dup->num_rows > 0) {
        throw new Exception("Bạn đã có đơn đặt cọc cho phòng này. Vui lòng kiểm tra lịch sử đặt cọc.");
    }

    // 3. Lấy số tiền cọc từ bảng rooms
    if (qltro_active_tenant_phone_exists($conn, $customer_phone)) {
        throw new Exception("Số điện thoại này đã thuộc về khách thuê đang hoạt động.");
    }
    if (qltro_open_deposit_phone_exists($conn, $customer_phone)) {
        throw new Exception("Số điện thoại này đang có phiếu cọc chờ xử lý.");
    }

    $deposit_amount = floatval($room['deposit'] ?? 0);
    if ($deposit_amount < 2000) {
        $deposit_amount = 500000; // Mặc định 500k nếu chưa cấu hình
    }

    // 4. Tạo record deposit
    // Dùng MySQL NOW() thay vì PHP date() để tránh lệch timezone
    $deposit_date = date('Y-m-d');
    $expected_move_in_date = date('Y-m-d', strtotime('+7 days'));

    $post_id_sql = $post_id ? $post_id : "NULL";
    
    $sql = "INSERT INTO deposits (house_id, room_id, user_id, post_id, customer_name, customer_phone, deposit_amount, deposit_date, expected_move_in_date, note, status, payment_expires_at)
            VALUES ($house_id, $room_id, $user_id, $post_id_sql, '$customer_name', '$customer_phone', $deposit_amount, '$deposit_date', '$expected_move_in_date', '$note', 'waiting_payment', DATE_ADD(NOW(), INTERVAL 5 MINUTE))";

    if (!$conn->query($sql)) {
        throw new Exception("Lỗi khi tạo đơn cọc: " . $conn->error);
    }
    $deposit_id = $conn->insert_id;

    // 5. Tạo link thanh toán PayOS
    $payOS = new PayOS(PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY);

    $orderCode = intval(substr(time(), -7) . str_pad($deposit_id, 3, '0', STR_PAD_LEFT));
    $amount = intval($deposit_amount);
    if ($amount < 2000) $amount = 2000;

    $roomName = $room['room_name'] ?? "P$room_id";
    $description = "Coc phong " . $roomName;
    $description = mb_substr(preg_replace('/[^\x00-\x7F]/', '', $description), 0, 25);

    $returnUrl  = PUBLIC_BASE_URL . "/backend_api/deposits/payos_deposit_return.php?deposit_id={$deposit_id}&success=true";
    $cancelUrl  = PUBLIC_BASE_URL . "/backend_api/deposits/payos_deposit_return.php?deposit_id={$deposit_id}&success=false";

    $paymentData = [
        "orderCode"   => $orderCode,
        "amount"      => $amount,
        "description" => $description ?: "Dat coc #{$deposit_id}",
        "expiredAt"   => time() + 300,
        "returnUrl"   => $returnUrl,
        "cancelUrl"   => $cancelUrl,
        "items"       => [
            [
                "name"     => "Tien coc phong " . $roomName,
                "quantity" => 1,
                "price"    => $amount,
            ]
        ],
    ];

    $response = $payOS->createPaymentLink($paymentData);

    // 6. Lưu orderCode và checkout_url vào DB
    $oc = $conn->real_escape_string($orderCode);
    $checkout = $conn->real_escape_string($response['checkoutUrl']);
    $qr_code_str = isset($response['qrCode']) ? "'" . $conn->real_escape_string($response['qrCode']) . "'" : "NULL";
    $bin = isset($response['bin']) ? "'" . $conn->real_escape_string($response['bin']) . "'" : "NULL";
    $acc_num = isset($response['accountNumber']) ? "'" . $conn->real_escape_string($response['accountNumber']) . "'" : "NULL";
    $acc_name = isset($response['accountName']) ? "'" . $conn->real_escape_string($response['accountName']) . "'" : "NULL";
    $desc = isset($response['description']) ? "'" . $conn->real_escape_string($response['description']) . "'" : "NULL";
    
    $conn->query("UPDATE deposits SET 
        payos_order_code = '$oc', 
        checkout_url = '$checkout', 
        qr_code = $qr_code_str,
        bank_bin = $bin,
        bank_account_number = $acc_num,
        bank_account_name = $acc_name,
        payment_description = $desc
        WHERE id = $deposit_id");

    $conn->commit();

    // Đọc lại expires_at từ DB (MySQL timezone chính xác)
    $exp_res = $conn->query("SELECT payment_expires_at FROM deposits WHERE id = $deposit_id");
    $expires_at_db = ($exp_res && $ex = $exp_res->fetch_assoc()) ? $ex['payment_expires_at'] : '';

    echo json_encode([
        "status"        => "success",
        "deposit_id"    => $deposit_id,
        "order_code"    => $orderCode,
        "amount"        => $amount,
        "checkout_url"  => $response['checkoutUrl'],
        "qr_code"       => $response['qrCode'] ?? null,
        "bank_bin"      => $response['bin'] ?? null,
        "bank_account_number" => $response['accountNumber'] ?? null,
        "bank_account_name"   => $response['accountName'] ?? null,
        "payment_description" => $response['description'] ?? null,
        "expires_at"    => $expires_at_db,
        "room_name"     => $room['room_name'],
        "house_name"    => $room['house_name'],
    ]);

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
