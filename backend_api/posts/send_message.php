<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $sender_id = isset($_POST['sender_id']) ? intval($_POST['sender_id']) : 0;
    $receiver_id = isset($_POST['receiver_id']) ? intval($_POST['receiver_id']) : 0;
    $post_id = isset($_POST['post_id']) && !empty($_POST['post_id']) ? intval($_POST['post_id']) : null;
    $content = isset($_POST['content']) ? $conn->real_escape_string($_POST['content']) : '';
    $image_url = null;

    // Xử lý upload ảnh nếu có
    if (isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
        $target_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/chat/";
        $file_extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
        $file_name = time() . "_" . uniqid() . "." . $file_extension;
        $target_file = $target_dir . $file_name;

        if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_file)) {
            $image_url = $file_name;
        }
    }

    if ($sender_id <= 0 || $receiver_id <= 0 || (empty($content) && empty($image_url))) {
        echo json_encode(["status" => "error", "message" => "Thiếu thông tin người gửi/nhận hoặc nội dung"]);
        exit;
    }

    $sql = "INSERT INTO messages (sender_id, receiver_id, post_id, content, image_url) VALUES (?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("iiiss", $sender_id, $receiver_id, $post_id, $content, $image_url);

    if ($stmt->execute()) {
        echo json_encode(["status" => "success", "message" => "Đã gửi tin nhắn"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Lỗi: " . $conn->error]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Chỉ chấp nhận phương thức POST"]);
}
?>
