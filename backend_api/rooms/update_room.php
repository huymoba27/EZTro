<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';

header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["status" => "error", "message" => "Phương thức không hợp lệ"]);
    exit;
}

$room_id = intval($_POST['room_id'] ?? 0);
$house_id = intval($_POST['house_id'] ?? 0);
$room_name = preg_replace('/\s+/', ' ', trim($_POST['room_name'] ?? ''));
$price = floatval($_POST['price'] ?? 0);
$deposit = floatval($_POST['deposit'] ?? 0);
$area = floatval($_POST['area'] ?? 0);
$max_tenants = intval($_POST['max_tenants'] ?? 0);

if ($room_id <= 0 || $house_id <= 0 || $room_name === '') {
    echo json_encode(["status" => "error", "message" => "Dữ liệu phòng không hợp lệ"]);
    exit;
}
if ($price <= 0 || $deposit < 0 || $area < 0 || $max_tenants <= 0) {
    echo json_encode(["status" => "error", "message" => "Giá thuê phải lớn hơn 0; tiền cọc, diện tích không được âm; số khách tối đa phải lớn hơn 0."]);
    exit;
}

$auth = qltro_auth_context($conn);
qltro_assert_can_access_room($conn, $auth, $room_id);
qltro_assert_can_access_house($conn, $auth, $house_id);

$dup_stmt = $conn->prepare("SELECT id FROM rooms WHERE house_id = ? AND LOWER(TRIM(room_name)) = LOWER(TRIM(?)) AND id != ? LIMIT 1");
$dup_stmt->bind_param("isi", $house_id, $room_name, $room_id);
$dup_stmt->execute();
if ($dup_stmt->get_result()->num_rows > 0) {
    $dup_stmt->close();
    echo json_encode(["status" => "error", "message" => "Tên phòng đã tồn tại trong nhà trọ này"]);
    exit;
}
$dup_stmt->close();

$stmt = $conn->prepare("UPDATE rooms SET house_id = ?, room_name = ?, price = ?, deposit = ?, area = ?, max_tenants = ? WHERE id = ?");
$stmt->bind_param("isdddii", $house_id, $room_name, $price, $deposit, $area, $max_tenants, $room_id);

if (!$stmt->execute()) {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
    $stmt->close();
    exit;
}
$stmt->close();

if (isset($_POST['deleted_images']) && !empty($_POST['deleted_images'])) {
    $deleted_images = explode(',', $_POST['deleted_images']);
    $target_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/rooms/";
    $delete_stmt = $conn->prepare("DELETE FROM room_images WHERE room_id = ? AND image_path = ?");

    foreach ($deleted_images as $img_name) {
        $img_name = trim($img_name);
        if ($img_name === '') {
            continue;
        }

        $delete_stmt->bind_param("is", $room_id, $img_name);
        $delete_stmt->execute();

        $full_path = $target_dir . basename($img_name);
        if (file_exists($full_path)) {
            @unlink($full_path);
        }
    }
    $delete_stmt->close();
}

if (isset($_FILES['images'])) {
    $target_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/rooms/";
    if (!file_exists($target_dir)) {
        mkdir($target_dir, 0777, true);
    }

    $image_stmt = $conn->prepare("INSERT INTO room_images (room_id, image_path) VALUES (?, ?)");
    foreach ($_FILES['images']['tmp_name'] as $key => $tmp_name) {
        if (empty($tmp_name)) {
            continue;
        }

        $file_name = time() . "_" . uniqid() . "_" . basename($_FILES['images']['name'][$key]);
        if (move_uploaded_file($tmp_name, $target_dir . $file_name)) {
            $image_stmt->bind_param("is", $room_id, $file_name);
            $image_stmt->execute();
        }
    }
    $image_stmt->close();
}

echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
?>
