<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("ngrok-skip-browser-warning: true");

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(["status" => "error", "message" => "Thiếu ID người dùng"]);
    exit;
}

$sql = "SELECT p.*, r.room_name, r.price as original_price, r.area, h.house_name, h.address_detail, h.city, h.ward, h.latitude, h.longitude,
               (SELECT GROUP_CONCAT(image_path) FROM room_images WHERE room_id = r.id) as images
        FROM favorites f
        JOIN posts p ON f.post_id = p.id
        JOIN rooms r ON p.room_id = r.id
        JOIN houses h ON r.house_id = h.id
        WHERE f.user_id = ?
        ORDER BY f.created_at DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$posts = [];
while ($row = $result->fetch_assoc()) {
    $posts[] = $row;
}

echo json_encode(["status" => "success", "data" => $posts]);

$stmt->close();
$conn->close();
?>
