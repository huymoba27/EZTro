<?php
include dirname(__DIR__, 2) . '/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'read';
$user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;
$noti_id = isset($_POST['notification_id']) ? (int)$_POST['notification_id'] : 0;

try {
    if ($user_id <= 0) throw new Exception("Thiếu ID người dùng");

    if ($action === 'read_all') {
        $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
        $stmt->bind_param("i", $user_id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Đã đánh dấu đọc tất cả"]);
        else throw new Exception($stmt->error);
    } else {
        // Mặc định: Đọc một thông báo cụ thể
        if ($noti_id <= 0) throw new Exception("Thiếu ID thông báo");
        $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
        $stmt->bind_param("ii", $noti_id, $user_id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Đã đánh dấu đọc"]);
        else throw new Exception($stmt->error);
    }

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
