<?php
// 1. Cấu hình hệ thống
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Nhận dữ liệu
    $user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    $auth = qltro_auth_context($conn);
    if (!$auth["verified"]) qltro_json_error("Bạn cần đăng nhập để tạo nhà trọ");
    if ($auth["role"] === "manager") qltro_json_error("Quản lý không có quyền tạo nhà trọ mới");
    if ($auth["role"] !== "admin") $user_id = (int)$auth["user_id"];
    $house_name = isset($_POST['house_name']) ? trim($_POST['house_name']) : '';
    
    $city = $_POST['city'] ?? '';
    $ward = $_POST['ward'] ?? '';
    $address_detail = $_POST['address_detail'] ?? '';
    $amenities_str = $_POST['amenities'] ?? "";
    $latitude = isset($_POST['latitude']) && $_POST['latitude'] !== '' ? floatval($_POST['latitude']) : null;
    $longitude = isset($_POST['longitude']) && $_POST['longitude'] !== '' ? floatval($_POST['longitude']) : null;
    $total_area = isset($_POST['total_area']) && $_POST['total_area'] !== '' ? floatval($_POST['total_area']) : null;
    $floors = isset($_POST['floors']) && $_POST['floors'] !== '' ? intval($_POST['floors']) : null;

    // Kiểm tra dữ liệu bắt buộc
    if (empty($house_name) || $user_id == 0) {
        echo json_encode(["status" => "error", "message" => "Vui lòng nhập đầy đủ tên nhà trọ!"]);
        exit;
    }

    // --- BƯỚC 1: KIỂM TRA TRÙNG TÊN (Dồn logic từ App qua) ---
    $check_sql = "SELECT id FROM houses WHERE house_name = ? AND user_id = ? LIMIT 1";
    $stmt_check = $conn->prepare($check_sql);
    $stmt_check->bind_param("si", $house_name, $user_id);
    $stmt_check->execute();
    if ($stmt_check->get_result()->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "Nhà trọ tên '$house_name' đã tồn tại trong danh sách của bạn!"]);
        exit;
    }

    // --- BƯỚC 2: XỬ LÝ UPLOAD ẢNH ---
    $image_db_name = ""; 
    if (isset($_FILES['image']) && $_FILES['image']['error'] == 0) {
        $target_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/houses/";
        if (!file_exists($target_dir)) mkdir($target_dir, 0777, true);
        
        $extension = pathinfo($_FILES["image"]["name"], PATHINFO_EXTENSION);
        $image_db_name = time() . "_" . uniqid() . "." . $extension;
        move_uploaded_file($_FILES["image"]["tmp_name"], $target_dir . $image_db_name);
    }

    // --- BƯỚC 3: LƯU VÀO DATABASE (Dùng Transaction để an toàn) ---
    try {
        $conn->begin_transaction();

        $sql = "INSERT INTO houses (user_id, house_name, city, ward, address_detail, image, latitude, longitude, total_area, floors) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        $stmt_ins = $conn->prepare($sql);
        $stmt_ins->bind_param("isssssdddi", $user_id, $house_name, $city, $ward, $address_detail, $image_db_name, $latitude, $longitude, $total_area, $floors);
        
        if ($stmt_ins->execute()) {
            $house_id = $conn->insert_id;
            
            // Lưu các tiện ích đi kèm
            if (!empty($amenities_str)) {
                $ids = explode(',', $amenities_str);
                $stmt_amenity = $conn->prepare("INSERT INTO house_amenities (house_id, amenity_id) VALUES (?, ?)");
                foreach ($ids as $a_id) {
                    $a_id = intval($a_id);
                    if($a_id > 0) {
                        $stmt_amenity->bind_param("ii", $house_id, $a_id);
                        $stmt_amenity->execute();
                    }
                }
            }
            
            $conn->commit();
            echo json_encode(["status" => "success", "message" => "Tạo nhà trọ mới thành công!", "house_id" => $house_id]);
        } else {
            throw new Exception($conn->error);
        }
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["status" => "error", "message" => "Lỗi lưu Database: " . $e->getMessage()]);
    }
}
?>
