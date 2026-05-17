<?php
// Trang trung gian sau khi khách thanh toán cọc xong (returnUrl / cancelUrl)
header("Content-Type: text/html; charset=UTF-8");

include dirname(__DIR__, 2) . '/config/config.php';

$deposit_id = isset($_GET['deposit_id']) ? intval($_GET['deposit_id']) : 0;
$success    = isset($_GET['success']) && $_GET['success'] === 'true';

// Nếu PayOS báo thành công, cập nhật deposit → pending (chờ admin xác nhận)
if ($success && $deposit_id > 0) {
    $conn->query("UPDATE deposits SET status = 'pending' WHERE id = $deposit_id AND status = 'waiting_payment'");
    
    // Cập nhật trạng thái phòng → deposited + đóng bài đăng
    $dep = $conn->query("SELECT d.house_id, d.room_id, d.customer_name, d.deposit_amount, r.room_name
                         FROM deposits d
                         JOIN rooms r ON d.room_id = r.id
                         WHERE d.id = $deposit_id");
    if ($dep && $row = $dep->fetch_assoc()) {
        $conn->query("UPDATE rooms SET status = 'deposited' WHERE id = " . $row['room_id']);
        $conn->query("UPDATE posts SET status = 'closed' WHERE room_id = " . $row['room_id'] . " AND status = 'active'");

        $house_id = (int)$row['house_id'];
        $room_id = (int)$row['room_id'];
        $customer_name = $conn->real_escape_string($row['customer_name'] ?? 'Khách thuê');
        $deposit_amount = (float)$row['deposit_amount'];
        $room_name = $conn->real_escape_string($row['room_name'] ?? 'N/A');
        $receipt_date = date('Y-m-d');
        $receipt_desc = $conn->real_escape_string("Thu tiền đặt cọc phòng $room_name - Khách: $customer_name");

        $receipt_exists = $conn->query("SELECT id FROM receipts
                                        WHERE house_id = $house_id
                                          AND room_id = $room_id
                                          AND receipt_type = 'deposit'
                                          AND tenant_name = '$customer_name'
                                          AND ABS(amount - $deposit_amount) < 0.01
                                        LIMIT 1")->fetch_assoc();
        if (!$receipt_exists) {
            $conn->query("INSERT INTO receipts (house_id, room_id, tenant_name, amount, receipt_date, receipt_type, description)
                          VALUES ($house_id, $room_id, '$customer_name', $deposit_amount, '$receipt_date', 'deposit', '$receipt_desc')");
        }
    }
}
?>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= $success ? 'Đặt cọc thành công' : 'Đã hủy đặt cọc' ?></title>
<style>
  body { font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: #f5f5f5; }
  .card { background: white; border-radius: 20px; padding: 40px; text-align: center; max-width: 320px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
  .icon { font-size: 72px; }
  h2 { margin: 16px 0 8px; color: <?= $success ? '#2e7d32' : '#c62828' ?>; }
  p { color: #666; font-size: 14px; }
</style>
</head>
<body>
  <div class="card">
    <div class="icon"><?= $success ? '✅' : '❌' ?></div>
    <h2><?= $success ? 'Đặt cọc thành công!' : 'Đã hủy đặt cọc' ?></h2>
    <p><?= $success ? "Phiếu cọc #{$deposit_id} đã được ghi nhận. Chủ trọ sẽ liên hệ bạn sớm." : 'Bạn đã hủy giao dịch. Vui lòng thử lại.' ?></p>
    <p style="margin-top:24px; font-size:12px; color:#aaa;">Đang quay về ứng dụng...</p>
  </div>
  <script>
    setTimeout(() => {
      window.location.href = "eztro://deposit?success=<?= $success ? 'true' : 'false' ?>&deposit_id=<?= $deposit_id ?>";
    }, 1500);
  </script>
</body>
</html>
