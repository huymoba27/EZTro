<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Content-Type: application/json; charset=UTF-8");

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception("Phương thức không hợp lệ");
    }

    $invoice_id = isset($_POST['invoice_id']) ? (int)$_POST['invoice_id'] : 0;
    if ($invoice_id <= 0) {
        throw new Exception("ID hóa đơn không hợp lệ");
    }

    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_invoice($conn, $auth, $invoice_id);

    $invoice_check = $conn->query("SELECT status, payos_order_code FROM invoices WHERE id = $invoice_id")->fetch_assoc();
    if (!$invoice_check) {
        throw new Exception("Không tìm thấy hóa đơn để xóa");
    }
    if ($invoice_check['status'] !== 'pending') {
        throw new Exception("Chỉ có thể xóa hóa đơn đang chờ thanh toán. Hóa đơn đã thanh toán, thất thu hoặc thanh toán một phần phải được giữ lại để đối soát.");
    }
    if (!empty($invoice_check['payos_order_code'])) {
        throw new Exception("Không thể xóa hóa đơn đã tạo giao dịch PayOS.");
    }
    $receipt_check = $conn->query("SELECT id FROM receipts WHERE invoice_id = $invoice_id LIMIT 1")->fetch_assoc();
    if ($receipt_check) {
        throw new Exception("Không thể xóa hóa đơn đã có phiếu thu liên quan.");
    }

    $conn->begin_transaction();

    if (!$conn->query("DELETE FROM invoice_details WHERE invoice_id = $invoice_id")) {
        throw new Exception("Lỗi xóa chi tiết: " . $conn->error);
    }
    if (!$conn->query("DELETE FROM invoice_logs WHERE invoice_id = $invoice_id")) {
        throw new Exception("Lỗi xóa nhật ký hóa đơn: " . $conn->error);
    }
    if (!$conn->query("DELETE FROM invoices WHERE id = $invoice_id")) {
        throw new Exception("Lỗi xóa hóa đơn: " . $conn->error);
    }

    $conn->commit();
    echo json_encode(["status" => "success", "message" => "Xóa hóa đơn thành công"]);
} catch (Exception $e) {
    if ($conn) $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
