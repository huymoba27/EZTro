<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

/**
 * Lấy danh sách nhân viên (manager) mà chủ trọ quản lý.
 * Một nhân viên thuộc quyền quản lý của chủ trọ nếu nhà họ đang quản lý (managed_house_id) 
 * thuộc sở hữu của chủ trọ đó (houses.user_id).
 */
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu ID chủ trọ", "data" => []]);
    exit;
}

try {
    // Query lấy danh sách nhân viên của chủ trọ này
    $sql = "SELECT u.id, u.full_name, u.phone, u.managed_house_id, h.house_name, u.created_at
            FROM users u
            JOIN houses h ON u.managed_house_id = h.id
            WHERE h.user_id = ? AND u.role = 'manager'
            ORDER BY u.created_at DESC";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);

    echo json_encode(["status" => "success", "data" => $result]);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage(), "data" => []]);
}
?>
