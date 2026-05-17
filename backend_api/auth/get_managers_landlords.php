<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

try {
    // Lấy tất cả người dùng có vai trò là landlord hoặc manager
    $sql = "SELECT id, full_name, phone, role FROM users WHERE role IN ('landlord', 'manager') ORDER BY full_name ASC";
    $result = $conn->query($sql);
    $data = [];
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
    }
    echo json_encode(["status" => "success", "data" => $data]);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
