<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$house_id = isset($_GET['house_id']) ? (int)$_GET['house_id'] : 0;
$room_id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
$status = isset($_GET['status']) ? $conn->real_escape_string($_GET['status']) : '';
$query = isset($_GET['query']) ? $conn->real_escape_string($_GET['query']) : '';
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? (int)$_GET['managed_house_id'] : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);
$include_deleted = isset($_GET['include_deleted']) && $_GET['include_deleted'] == '1';

// 🎯 Query cơ bản lấy thông tin phòng + nhà + giá điện nước
$sql = "SELECT r.*, h.house_name, h.address_detail, h.ward, h.city,
               (SELECT GROUP_CONCAT(a.name SEPARATOR ', ') FROM house_amenities ha JOIN amenities a ON ha.amenity_id = a.id WHERE ha.house_id = h.id) as house_amenities,
               (SELECT price FROM services WHERE house_id = h.id AND service_type = 'electric' LIMIT 1) as electric_price,
               (SELECT price FROM services WHERE house_id = h.id AND service_type = 'water' LIMIT 1) as water_price,
               (SELECT tenant_name FROM tenants WHERE room_id = r.id AND is_representative = 1 AND status = 'active' LIMIT 1) as customer_name,
               (SELECT phone FROM tenants WHERE room_id = r.id AND is_representative = 1 AND status = 'active' LIMIT 1) as customer_phone,
               (SELECT id FROM tenants WHERE room_id = r.id AND is_representative = 1 AND status = 'active' LIMIT 1) as tenant_id,
               (SELECT id FROM contracts WHERE room_id = r.id AND status = 'active' LIMIT 1) as contract_id
        FROM rooms r
        JOIN houses h ON r.house_id = h.id
        WHERE 1=1 ";

if (!$include_deleted) {
    $sql .= " AND r.status != 'deleted' AND h.status = 'active' ";
}

// 1. 🛡️ PHÂN QUYỀN
if ($role === 'admin') {
    // Admin thấy hết
} else if ($role === 'manager' && $managed_house_id > 0) {
    $sql .= " AND r.house_id = $managed_house_id ";
} else {
    // Landlord mặc định
    $sql .= " AND h.user_id = $user_id ";
}

if ($room_id > 0) {
    $sql .= " AND r.id = $room_id ";
}
if ($house_id > 0) {
    $sql .= " AND r.house_id = $house_id ";
}
if ($status === 'available') {
    // Các phòng có thể thuê mới (Trống hoặc đang ở ghép chưa đầy)
    $sql .= " AND r.status IN ('empty', 'available', 'posted') ";
} else if ($status === 'occupied') {
    // Các phòng đang có người ở (Bao gồm cả đầy và chưa đầy)
    $sql .= " AND (r.status = 'full' OR r.status = 'available') ";
} else if ($status === 'has_space') {
    // Chỉ các phòng đang ở ghép nhưng vẫn CÒN CHỖ (Dành cho thêm thành viên)
    $sql .= " AND r.status = 'available' AND r.current_tenants < r.max_tenants ";
} else if ($status !== '' && $status !== 'all') {
    $sql .= " AND r.status = '$status' ";
}

if ($query !== '') {
    $sql .= " AND (r.room_name LIKE '%$query%' OR h.house_name LIKE '%$query%') ";
}

$sql .= " ORDER BY h.house_name ASC, r.room_name ASC";

$result = $conn->query($sql);
$data = [];

if ($result) {
    while ($row = $result->fetch_assoc()) {
        $r_id = $row['id'];
        
        // Xử lý ảnh từ bảng room_images
        $images = [];
        $img_res = $conn->query("SELECT image_path FROM room_images WHERE room_id = $r_id");
        while($img_row = $img_res->fetch_assoc()) $images[] = $img_row['image_path'];
        $row['images_list'] = $images;

        // Nếu là lấy chi tiết 1 phòng -> lấy thêm danh sách khách và hóa đơn
        if ($room_id > 0) {
            // 1. Danh sách khách thuê
            $tenants = [];
            $t_res = $conn->query("SELECT * FROM tenants WHERE room_id = $r_id AND status = 'active' AND deleted_at IS NULL");
            while($t_row = $t_res->fetch_assoc()) {
                $t_row['room_name'] = $row['room_name'];
                $t_row['house_name'] = $row['house_name'];
                $t_row['house_id'] = $row['house_id'];
                $tenants[] = $t_row;
            }
            $row['tenants_list'] = $tenants;

            // 2. Danh sách hóa đơn gần đây
            $invoices = [];
            $active_contract_id = (int)($row['contract_id'] ?? 0);
            $invoice_where = $active_contract_id > 0 ? "contract_id = $active_contract_id" : "room_id = $r_id";
            $i_res = $conn->query("SELECT * FROM invoices WHERE $invoice_where ORDER BY id DESC LIMIT 12");
            while($i_row = $i_res->fetch_assoc()) {
                $i_row['room_name'] = $row['room_name'];
                $i_row['house_name'] = $row['house_name'];
                $i_row['house_id'] = $row['house_id'];
                $invoices[] = $i_row;
            }
            $row['invoice_list'] = $invoices;
            
            // 3. Thông tin hợp đồng chi tiết (Nếu có)
            if ($row['contract_id']) {
                $c_id = $row['contract_id'];
                $contract = $conn->query("SELECT * FROM contracts WHERE id = $c_id")->fetch_assoc();
                if ($contract) {
                    // Gộp an toàn: Không đè id và status của phòng
                    foreach ($contract as $key => $value) {
                        if ($key !== 'id' && $key !== 'status') {
                            $row[$key] = $value;
                        }
                    }
                    $row['contract_data'] = $contract; 
                }
            }
        }
        $data[] = $row;
    }

    if ($room_id > 0 && count($data) > 0) {
        echo json_encode(["status" => "success", "data" => $data[0]]);
    } else {
        echo json_encode(["status" => "success", "data" => $data]);
    }
} else {
    echo json_encode(["status" => "error", "message" => $conn->error]);
}
?>
