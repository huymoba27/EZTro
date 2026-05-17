<?php
// 1. Cấu hình hệ thống
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Ép kiểu và filter dữ liệu
    $house_id = intval($_POST['house_id']);
    $room_name = preg_replace('/\s+/', ' ', trim($_POST['room_name']));
    $price = doubleval($_POST['price']);
    $deposit = doubleval($_POST['deposit']);
    $area = doubleval($_POST['area']);
    $max_tenants = isset($_POST['max_tenants']) ? intval($_POST['max_tenants']) : 0;
    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_house($conn, $auth, $house_id);

    if (empty($room_name) || $house_id == 0) {
        echo json_encode(["status" => "error", "message" => "Vui lòng nhập đầy đủ tên phòng!"]);
        exit;
    }
    if ($price <= 0 || $deposit < 0 || $area < 0 || $max_tenants <= 0) {
        echo json_encode(["status" => "error", "message" => "Giá thuê phải lớn hơn 0; tiền cọc, diện tích không được âm; số khách tối đa phải lớn hơn 0."]);
        exit;
    }

    // --- 🔍 BƯỚC 1: KIỂM TRA TRÙNG TÊN PHÒNG TRONG NHÀ ---
    $check_sql = "SELECT id FROM rooms WHERE house_id = ? AND LOWER(TRIM(room_name)) = LOWER(TRIM(?)) LIMIT 1";
    $stmt_check = $conn->prepare($check_sql);
    $stmt_check->bind_param("is", $house_id, $room_name);
    $stmt_check->execute();
    if ($stmt_check->get_result()->num_rows > 0) {
        echo json_encode([
            "status" => "error", 
            "message" => "Phòng '$room_name' đã tồn tại trong nhà này rồi!"
        ]);
        exit;
    }

    // --- 💾 BƯỚC 2: TẠO PHÒNG MỚI (Transaction) ---
    try {
        $conn->begin_transaction();

        $sql = "INSERT INTO rooms (house_id, room_name, price, deposit, area, max_tenants, status) 
                VALUES (?, ?, ?, ?, ?, ?, 'empty')";
        $stmt_ins = $conn->prepare($sql);
        $stmt_ins->bind_param("isdddi", $house_id, $room_name, $price, $deposit, $area, $max_tenants);
        
        if ($stmt_ins->execute()) {
            $room_id = $conn->insert_id;
            $uploaded_images = [];

            // 📸 Xử lý upload NHIỀU ảnh
            if (isset($_FILES['images'])) {
                $target_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/rooms/";
                if (!file_exists($target_dir)) mkdir($target_dir, 0777, true);

                $stmt_img = $conn->prepare("INSERT INTO room_images (room_id, image_path) VALUES (?, ?)");
                foreach ($_FILES['images']['tmp_name'] as $key => $tmp_name) {
                    if (!empty($tmp_name)) {
                        $ext = pathinfo($_FILES['images']['name'][$key], PATHINFO_EXTENSION);
                        $file_name = time() . "_" . uniqid() . "." . $ext;
                        
                        if (move_uploaded_file($tmp_name, $target_dir . $file_name)) {
                            $stmt_img->bind_param("is", $room_id, $file_name);
                            $stmt_img->execute();
                            $uploaded_images[] = $file_name;
                        }
                    }
                }
            }

            $conn->commit();
            echo json_encode([
                "status" => "success", 
                "message" => "Tạo phòng thành công!",
                "room_id" => $room_id,
                "images_count" => count($uploaded_images)
            ]);
        } else {
            throw new Exception($conn->error);
        }
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(["status" => "error", "message" => "Lỗi Database: " . $e->getMessage()]);
    }
}
?>
