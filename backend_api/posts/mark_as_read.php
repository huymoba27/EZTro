<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $sender_id = isset($_POST['sender_id']) ? intval($_POST['sender_id']) : 0;
    $receiver_id = isset($_POST['receiver_id']) ? intval($_POST['receiver_id']) : 0;

    if ($sender_id <= 0 || $receiver_id <= 0) {
        echo json_encode(["status" => "error", "message" => "Thiếu ID"]);
        exit;
    }

    // Đánh dấu tất cả tin nhắn từ sender_id gửi cho receiver_id là đã đọc
    $sql = "UPDATE messages SET is_read = 1 WHERE sender_id = ? AND receiver_id = ? AND is_read = 0";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("ii", $sender_id, $receiver_id);

    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Đã đánh dấu đã đọc"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Lỗi: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Chỉ chấp nhận POST"]);
}
?>
