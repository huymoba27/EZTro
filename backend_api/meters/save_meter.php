<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'save';
$id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
$c_id = isset($_POST['contract_id']) ? (int)$_POST['contract_id'] : 0;
$r_id = isset($_POST['room_id']) ? (int)$_POST['room_id'] : 0;
$old_e = isset($_POST['old_e']) ? (int)$_POST['old_e'] : 0;
$new_e = isset($_POST['new_e']) ? (int)$_POST['new_e'] : 0;
$old_w = isset($_POST['old_w']) ? (int)$_POST['old_w'] : 0;
$new_w = isset($_POST['new_w']) ? (int)$_POST['new_w'] : 0;
$month = isset($_POST['month']) ? (int)$_POST['month'] : 0;
$year = isset($_POST['year']) ? (int)$_POST['year'] : 0;
$date = date('Y-m-d H:i:s');

try {
    $auth = qltro_auth_context($conn);
    $electric_image = "";
    $water_image = "";
    $upload_dir = $_SERVER['DOCUMENT_ROOT'] . "/ql_tro/uploads/meters/";
    if (!is_dir($upload_dir)) mkdir($upload_dir, 0777, true);

    if (isset($_FILES['electric_image']) && $_FILES['electric_image']['error'] == 0) {
        $electric_image = time() . "_e_" . $_FILES['electric_image']['name'];
        move_uploaded_file($_FILES['electric_image']['tmp_name'], $upload_dir . $electric_image);
    }
    if (isset($_FILES['water_image']) && $_FILES['water_image']['error'] == 0) {
        $water_image = time() . "_w_" . $_FILES['water_image']['name'];
        move_uploaded_file($_FILES['water_image']['tmp_name'], $upload_dir . $water_image);
    }

    if ($action === 'delete') {
        if ($id <= 0) throw new Exception("Thiếu ID bản ghi cần xóa.");

        qltro_assert_can_access_meter($conn, $auth, $id);
        $m = $conn->query("SELECT contract_id, billing_month, billing_year, electric_image, water_image FROM meter_readings WHERE id = $id")->fetch_assoc();
        if (!$m) throw new Exception("Không tìm thấy bản ghi chỉ số.");

        $cid = (int)$m['contract_id'];
        $mon = (int)$m['billing_month'];
        $yea = (int)$m['billing_year'];
        $inv = $conn->query("SELECT id FROM invoices WHERE contract_id = $cid AND billing_month = $mon AND billing_year = $yea LIMIT 1")->fetch_assoc();
        if ($inv) {
            throw new Exception("Chỉ số này đã được dùng để lập hóa đơn. Vui lòng xóa hóa đơn tháng $mon/$yea trước khi xóa chỉ số.");
        }

        $delete_images = [];
        if (!empty($m['electric_image'])) $delete_images[] = $m['electric_image'];
        if (!empty($m['water_image'])) $delete_images[] = $m['water_image'];

        $stmt = $conn->prepare("DELETE FROM meter_readings WHERE id = ?");
        $stmt->bind_param("i", $id);
        if (!$stmt->execute()) throw new Exception($stmt->error);

        foreach ($delete_images as $image_name) {
            if (file_exists($upload_dir . $image_name)) @unlink($upload_dir . $image_name);
        }

        echo json_encode(["status" => "success", "message" => "Xóa chỉ số thành công"]);
        exit;
    }

    if ($action === 'update') {
        if ($id <= 0) throw new Exception("Thiếu ID bản ghi cần cập nhật.");

        qltro_assert_can_access_meter($conn, $auth, $id);
        $m = $conn->query("SELECT contract_id, room_id, billing_month, billing_year, old_electric, old_water, electric_image, water_image FROM meter_readings WHERE id = $id")->fetch_assoc();
        if (!$m) throw new Exception("Không tìm thấy bản ghi chỉ số.");

        $cid = (int)$m['contract_id'];
        $mon = (int)$m['billing_month'];
        $yea = (int)$m['billing_year'];
        $old_e_db = (int)$m['old_electric'];
        $old_w_db = (int)$m['old_water'];
        $inv = $conn->query("SELECT id FROM invoices WHERE contract_id = $cid AND billing_month = $mon AND billing_year = $yea LIMIT 1")->fetch_assoc();
        if ($inv) {
            throw new Exception("Chỉ số này đã được dùng để lập hóa đơn. Vui lòng xóa hóa đơn tháng $mon/$yea trước khi sửa.");
        }
        if ($new_e < $old_e_db || $new_w < $old_w_db) {
            throw new Exception("Chỉ số mới không được nhỏ hơn chỉ số cũ ($old_e_db/$old_w_db).");
        }

        $sql_up = "UPDATE meter_readings SET new_electric = ?, new_water = ?";
        if (!empty($electric_image)) {
            $sql_up .= ", electric_image = '$electric_image'";
            if (!empty($m['electric_image']) && file_exists($upload_dir . $m['electric_image'])) @unlink($upload_dir . $m['electric_image']);
        }
        if (!empty($water_image)) {
            $sql_up .= ", water_image = '$water_image'";
            if (!empty($m['water_image']) && file_exists($upload_dir . $m['water_image'])) @unlink($upload_dir . $m['water_image']);
        }
        $sql_up .= " WHERE id = ?";

        $stmt = $conn->prepare($sql_up);
        $stmt->bind_param("iii", $new_e, $new_w, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

    if ($r_id <= 0 || $month < 1 || $month > 12 || $year <= 0) {
        throw new Exception("Thiếu thông tin phòng hoặc thời gian chốt số.");
    }
    if ($new_e < $old_e || $new_w < $old_w) {
        throw new Exception("Chỉ số mới không được nhỏ hơn chỉ số cũ ($old_e/$old_w).");
    }

    qltro_assert_can_access_room($conn, $auth, $r_id);

    if ($c_id <= 0) {
        $active_contract = $conn->query("SELECT id FROM contracts WHERE room_id = $r_id AND status = 'active' ORDER BY id DESC LIMIT 1")->fetch_assoc();
        if ($active_contract) {
            $c_id = (int)$active_contract['id'];
        }
    }

    $contract = $conn->query("SELECT id FROM contracts WHERE id = $c_id AND room_id = $r_id AND status = 'active' LIMIT 1")->fetch_assoc();
    if (!$contract) throw new Exception("Không tìm thấy hợp đồng đang hoạt động của phòng này.");

    $check = $conn->query("SELECT id FROM meter_readings WHERE contract_id = $c_id AND billing_month = $month AND billing_year = $year")->fetch_assoc();
    if ($check) throw new Exception("Tháng này đã được chốt số rồi!");

    $stmt = $conn->prepare("INSERT INTO meter_readings (contract_id, room_id, reading_date, billing_month, billing_year, old_electric, new_electric, old_water, new_water, electric_image, water_image) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("iisiiiiiiss", $c_id, $r_id, $date, $month, $year, $old_e, $new_e, $old_w, $new_w, $electric_image, $water_image);

    if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Lưu chỉ số thành công", "data" => ["id" => $stmt->insert_id]]);
    else throw new Exception($stmt->error);
} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
