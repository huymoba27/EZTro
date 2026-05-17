<?php
include dirname(__DIR__, 2) . '/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Content-Type: application/json; charset=UTF-8");

$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$action = $_GET['action'] ?? 'list';
$filter = $_GET['filter'] ?? 'all';

if ($user_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu ID người dùng"]);
    exit;
}

if ($action === 'unread_count') {
    $sql = "SELECT COUNT(*) as unread FROM notifications WHERE user_id = $user_id AND is_read = 0";
    $res = $conn->query($sql)->fetch_assoc();
    echo json_encode(["status" => "success", "unread" => (int)$res['unread']]);
    exit;
}

// MẶC ĐỊNH: LẤY DANH SÁCH THÔNG BÁO
$sql = "SELECT * FROM notifications WHERE user_id = $user_id ";
if ($filter !== 'all') {
    $sql .= " AND type = '" . $conn->real_escape_string($filter) . "' ";
}
$sql .= " ORDER BY created_at DESC LIMIT 50";

$result = $conn->query($sql);
$data = [];
while ($row = $result->fetch_assoc()) $data[] = $row;
echo json_encode(["status" => "success", "data" => $data]);
?>
