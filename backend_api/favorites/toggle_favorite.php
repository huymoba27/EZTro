<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $user_id = $_POST['user_id'] ?? null;
    $post_id = $_POST['post_id'] ?? null;

    if (!$user_id || !$post_id) {
        echo json_encode(["status" => "error", "message" => "Thiếu thông tin người dùng hoặc bài đăng"]);
        exit;
    }

    // Kiểm tra xem đã yêu thích chưa
    $check = $conn->prepare("SELECT id FROM favorites WHERE user_id = ? AND post_id = ?");
    $check->bind_param("ii", $user_id, $post_id);
    $check->execute();
    $res = $check->get_result();

    if ($res->num_rows > 0) {
        // Nếu đã tồn tại thì xóa (Unfavorite)
        $stmt = $conn->prepare("DELETE FROM favorites WHERE user_id = ? AND post_id = ?");
        $stmt->bind_param("ii", $user_id, $post_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "action" => "removed", "message" => "Đã bỏ yêu thích"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Lỗi: " . $conn->error]);
        }
    } else {
        // Nếu chưa có thì thêm (Favorite)
        $stmt = $conn->prepare("INSERT INTO favorites (user_id, post_id) VALUES (?, ?)");
        $stmt->bind_param("ii", $user_id, $post_id);
        if ($stmt->execute()) {
            echo json_encode(["status" => "success", "action" => "added", "message" => "Đã thêm vào yêu thích"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Lỗi: " . $conn->error]);
        }
    }
    $stmt->close();
    $check->close();
}
$conn->close();
?>
