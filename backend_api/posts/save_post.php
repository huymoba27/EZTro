<?php
include dirname(__DIR__, 2) . '/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'save';
$id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
$room_id = isset($_POST['room_id']) ? (int)$_POST['room_id'] : 0;
$title = isset($_POST['title']) ? $conn->real_escape_string($_POST['title']) : '';
$description = isset($_POST['description']) ? $conn->real_escape_string($_POST['description']) : '';
$price_display = isset($_POST['price_display']) ? $conn->real_escape_string($_POST['price_display']) : '';
$house_rules = isset($_POST['house_rules']) ? $conn->real_escape_string($_POST['house_rules']) : '';
$images = isset($_POST['images']) ? $conn->real_escape_string($_POST['images']) : '';
$status = isset($_POST['status']) ? $conn->real_escape_string($_POST['status']) : 'active';

try {
    if ($action === 'close' || $action === 'delete') {
        if ($id <= 0) throw new Exception("Thiếu ID tin đăng");
        $new_status = ($action === 'close') ? 'closed' : 'deleted';
        $stmt = $conn->prepare("UPDATE posts SET status = ? WHERE id = ?");
        $stmt->bind_param("si", $new_status, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Đã cập nhật trạng thái tin đăng"]);
        else throw new Exception($stmt->error);
        exit;
    }

    if ($room_id <= 0 || $title === '') throw new Exception("Thiếu thông tin tin đăng");

    if ($action === 'update') {
        if ($id <= 0) throw new Exception("Thiếu ID tin đăng");
        $stmt = $conn->prepare("UPDATE posts SET title = ?, description = ?, price_display = ?, house_rules = ?, images = ?, status = ? WHERE id = ?");
        $stmt->bind_param("ssssssi", $title, $description, $price_display, $house_rules, $images, $status, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
        else throw new Exception($stmt->error);
    } else {
        // SAVE (Insert)
        // Kiểm tra xem phòng này đã có tin đăng chưa
        $check = $conn->query("SELECT id FROM posts WHERE room_id = $room_id AND status = 'active'")->num_rows;
        if ($check > 0) throw new Exception("Phòng này đã có tin đăng đang hoạt động!");

        $stmt = $conn->prepare("INSERT INTO posts (room_id, title, description, price_display, house_rules, images, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())");
        $stmt->bind_param("issssss", $room_id, $title, $description, $price_display, $house_rules, $images, $status);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Đăng tin thành công", "id" => $stmt->insert_id]);
        else throw new Exception($stmt->error);
    }

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
