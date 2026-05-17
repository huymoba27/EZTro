<?php
// Trang trung gian sau khi người dùng thanh toán xong (returnUrl / cancelUrl)
// Flutter sẽ detect URL này trong WebView để biết kết quả
header("Content-Type: text/html; charset=UTF-8");

include dirname(__DIR__, 2) . '/config/config.php';

$invoice_id = isset($_GET['invoice_id']) ? intval($_GET['invoice_id']) : 0;
$success    = isset($_GET['success']) && $_GET['success'] === 'true';
$status_code = $_GET['code'] ?? '';

// Nếu PayOS báo PAID (code=00), cập nhật ngay ở đây (fallback nếu webhook chậm)
if ($success && $invoice_id > 0) {
    $conn->query("UPDATE invoices SET status = 'paid' WHERE id = $invoice_id AND status = 'pending'");
}
?>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= $success ? 'Thanh toán thành công' : 'Đã hủy thanh toán' ?></title>
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
    <h2><?= $success ? 'Thanh toán thành công!' : 'Đã hủy thanh toán' ?></h2>
    <p><?= $success ? "Hóa đơn #{$invoice_id} đã được ghi nhận." : 'Bạn đã hủy giao dịch. Vui lòng thử lại.' ?></p>
    <p style="margin-top:24px; font-size:12px; color:#aaa;">Đang quay về ứng dụng...</p>
  </div>
  <script>
    // Gửi tín hiệu cho Flutter WebView thông qua URL scheme
    setTimeout(() => {
      window.location.href = "eztro://payment?success=<?= $success ? 'true' : 'false' ?>&invoice_id=<?= $invoice_id ?>";
    }, 1500);
  </script>
</body>
</html>
