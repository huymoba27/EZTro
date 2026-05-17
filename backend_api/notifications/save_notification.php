<?php
include dirname(__DIR__, 2) . '/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Nhận dữ liệu từ body (JSON hoặc POST)
$data = json_decode(file_get_contents("php://input"), true);
if (!$data) $data = $_POST;

$user_id = isset($data['user_id']) ? (int)$data['user_id'] : 0;
$title = isset($data['title']) ? $conn->real_escape_string($data['title']) : '';
$desc = isset($data['description']) ? $conn->real_escape_string($data['description']) : '';
$type = isset($data['type']) ? $conn->real_escape_string($data['type']) : 'system';
$metadata = isset($data['metadata']) ? (is_array($data['metadata']) ? json_encode($data['metadata']) : $data['metadata']) : '{}';

try {
    if ($user_id <= 0 || $title === '') throw new Exception("Thiếu thông tin thông báo");

    $stmt = $conn->prepare("INSERT INTO notifications (user_id, title, description, type, metadata, created_at, is_read) VALUES (?, ?, ?, ?, ?, NOW(), 0)");
    $stmt->bind_param("issss", $user_id, $title, $desc, $type, $metadata);
    
    if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Gửi thông báo thành công", "id" => $stmt->insert_id]);
    else throw new Exception($stmt->error);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
