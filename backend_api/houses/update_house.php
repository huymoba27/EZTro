<?php
// 1. Dùng đường dẫn tuyệt đối cho an toàn
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Nhận dữ liệu
    $id = isset($_POST['id']) ? intval($_POST['id']) : 0;
    $house_name = isset($_POST['house_name']) ? trim($_POST['house_name']) : '';
    $city = $_POST['city'] ?? '';
    $ward = $_POST['ward'] ?? '';
    $address_detail = $_POST['address_detail'] ?? '';
    $amenity_ids_str = $_POST['amenity_ids'] ?? "";
    
    $latitude = isset($_POST['latitude']) && $_POST['latitude'] !== '' ? floatval($_POST['latitude']) : null;
    $longitude = isset($_POST['longitude']) && $_POST['longitude'] !== '' ? floatval($_POST['longitude']) : null;
    $total_area = isset($_POST['total_area']) && $_POST['total_area'] !== '' ? floatval($_POST['total_area']) : null;
    $floors = isset($_POST['floors']) && $_POST['floors'] !== '' ? intval($_POST['floors']) : null;

    if ($id <= 0 || empty($house_name)) {
        echo json_encode(["status" => "error", "message" => "Dữ liệu không hợp lệ!"]);
        exit;
    }

    // Xử lý ảnh nếu có upload mới
    $auth = qltro_auth_context($conn);
    qltro_assert_can_manage_house_profile($conn, $auth, $id);

    $image_update_sql = "";
    $new_image_name = "";
    if (isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
        $target_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/houses/";
        if (!file_exists($target_dir)) mkdir($target_dir, 0777, true);
        
        $extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
        $new_image_name = time() . "_" . uniqid() . "." . $extension;
        if (move_uploaded_file($_FILES["image"]["tmp_name"], $target_dir . $new_image_name)) {
            $image_update_sql = ", image = ?";
        }
    }

    try {
        $conn->begin_transaction();

        // 1. Cập nhật bảng houses
        $sql = "UPDATE houses SET 
                house_name = ?, 
                city = ?, 
                ward = ?, 
                address_detail = ?, 
                latitude = ?, 
                longitude = ?, 
                total_area = ?, 
                floors = ?";
        
        if (!empty($image_update_sql)) {
            $sql .= $image_update_sql;
        }
        $sql .= " WHERE id = ?";

        $stmt = $conn->prepare($sql);
        
        if (!empty($image_update_sql)) {
            $stmt->bind_param("ssssdddisi", 
                $house_name, $city, $ward, $address_detail, 
                $latitude, $longitude, $total_area, $floors, $new_image_name, $id);
        } else {
            $stmt->bind_param("ssssdddii", 
                $house_name, $city, $ward, $address_detail, 
                $latitude, $longitude, $total_area, $floors, $id);
        }

        if ($stmt->execute()) {
            // 2. Cập nhật tiện ích (Xóa cũ thêm mới)
            $conn->query("DELETE FROM house_amenities WHERE house_id = $id");
            if (!empty($amenity_ids_str)) {
                $ids = explode(',', $amenity_ids_str);
                $stmt_amenity = $conn->prepare("INSERT INTO house_amenities (house_id, amenity_id) VALUES (?, ?)");
                foreach ($ids as $a_id) {
                    $a_id = intval($a_id);
                    if ($a_id > 0) {
                        $stmt_amenity->bind_param("ii", $id, $a_id);
                        $stmt_amenity->execute();
                    }
                }
            }

            $conn->commit();
            echo json_encode(["status" => "success", "message" => "Cập nhật thành công!"]);
        } else {
            throw new Exception($stmt->error);
        }
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["status" => "error", "message" => "Lỗi hệ thống: " . $e->getMessage()]);
    }
}
$conn->close();
?>
