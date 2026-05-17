<?php
include dirname(__DIR__, 2) . '/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$other_id = isset($_GET['other_id']) ? (int)$_GET['other_id'] : 0;
$action = $_GET['action'] ?? 'list';

if ($user_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu ID người dùng"]);
    exit;
}

// ---------------------------------------------------------
// 1. ACTION: HISTORY (LỊCH SỬ CHAT GIỮA 2 NGƯỜI)
// ---------------------------------------------------------
if ($action === 'history' && $other_id > 0) {
    $sql = "SELECT * FROM messages 
            WHERE (sender_id = $user_id AND receiver_id = $other_id) 
               OR (sender_id = $other_id AND receiver_id = $user_id) 
            ORDER BY created_at ASC";
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) $data[] = $row;
    echo json_encode(["status" => "success", "data" => $data]);
    exit;
}

// ---------------------------------------------------------
// 2. MẶC ĐỊNH: LẤY DANH SÁCH CÁC CUỘC HỘI THOẠI (CHAT LIST)
// ---------------------------------------------------------
$sql = "SELECT m1.*, u.full_name as other_name, u.avatar as other_avatar 
        FROM messages m1
        JOIN (
            SELECT MAX(id) as max_id, 
                   IF(sender_id = $user_id, receiver_id, sender_id) as other_user
            FROM messages
            WHERE sender_id = $user_id OR receiver_id = $user_id
            GROUP BY other_user
        ) m2 ON m1.id = m2.max_id
        JOIN users u ON m2.other_user = u.id
        ORDER BY m1.created_at DESC";

$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;
echo json_encode(["status" => "success", "data" => $data]);
?>
