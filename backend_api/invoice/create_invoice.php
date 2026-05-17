<?php
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $room_id = intval($_POST['room_id']);
    $month = intval($_POST['billing_month']);
    $year = intval($_POST['billing_year']);
    $is_meter_checked = $_POST['is_meter_checked'] == "1";

    if ($room_id <= 0 || $month <= 0 || $year <= 0) {
        echo json_encode(["status" => "error", "message" => "Dữ liệu không hợp lệ!"]);
        exit;
    }

    // 1. Lấy hợp đồng đang hoạt động
    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_room($conn, $auth, $room_id);

    $contract = $conn->query("SELECT * FROM contracts WHERE room_id = $room_id AND status = 'active' LIMIT 1")->fetch_assoc();
    if (!$contract) { 
        echo json_encode(["status" => "error", "message" => "Không tìm thấy hợp đồng hoạt động!"]); 
        exit; 
    }
    $contract_id = $contract['id'];

    // 1.5 CHẶN TRÙNG HÓA ĐƠN (Kiểm tra theo Hợp đồng + Tháng/Năm)
    $stmt_check = $conn->prepare("SELECT id FROM invoices WHERE contract_id = ? AND billing_month = ? AND billing_year = ? LIMIT 1");
    $stmt_check->bind_param("iii", $contract_id, $month, $year);
    $stmt_check->execute();
    if ($stmt_check->get_result()->num_rows > 0) {
        echo json_encode(["status" => "error", "message" => "Hợp đồng này đã được lập hóa đơn tháng $month/$year rồi!"]);
        exit;
    }

    // 2. Nếu Flutter yêu cầu CHỐT SỐ (Lưu vào database)
    if (!$is_meter_checked && isset($_POST['new_elec'])) {
        $new_elec = intval($_POST['new_elec']);
        $new_water = intval($_POST['new_water']);
        
        // Kiểm tra xem tháng này đã chốt số chưa, nếu chưa thì mới insert
        $check_meter = $conn->query("SELECT id FROM meter_readings WHERE contract_id = $contract_id AND billing_month = $month AND billing_year = $year LIMIT 1");
        if ($check_meter->num_rows == 0) {
            $last = $conn->query("SELECT new_electric, new_water FROM meter_readings WHERE contract_id = $contract_id ORDER BY id DESC LIMIT 1")->fetch_assoc();
            $old_elec = $last['new_electric'] ?? $contract['start_electric_index'];
            $old_water = $last['new_water'] ?? $contract['start_water_index'];

            if ($new_elec < $old_elec) {
                echo json_encode(["status" => "error", "message" => "Số điện mới không được nhỏ hơn số điện cũ!"]);
                exit;
            }
            if ($new_water < $old_water) {
                echo json_encode(["status" => "error", "message" => "Số nước mới không được nhỏ hơn số nước cũ!"]);
                exit;
            }

            $stmt_meter = $conn->prepare("INSERT INTO meter_readings (contract_id, room_id, billing_month, billing_year, old_electric, new_electric, old_water, new_water, reading_date) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())");
            $stmt_meter->bind_param("iiiiiiii", $contract_id, $room_id, $month, $year, $old_elec, $new_elec, $old_water, $new_water);
            $stmt_meter->execute();
        }
    }

    // 3. TÍNH TOÁN DỮ LIỆU ĐỂ TRẢ VỀ HOẶC LƯU HÓA ĐƠN
    $meter = $conn->query("SELECT * FROM meter_readings WHERE contract_id = $contract_id AND billing_month = $month AND billing_year = $year")->fetch_assoc();
    $services = $conn->query("SELECT service_name, service_price, unit, charge_type FROM contract_services WHERE contract_id = $contract_id");
    
    $total_bill = floatval($contract['rent_price']);
    $base_total = floatval($contract['rent_price']);
    
    // 🔥 LOGIC TÍNH TIỀN PHÒNG THEO NGÀY (PRO-RATA)
    $is_pro_rata = isset($_POST['is_pro_rata']) && $_POST['is_pro_rata'] == "1";
    $rent_display_name = "Tiền phòng";
    
    if ($is_pro_rata && isset($_POST['start_date']) && isset($_POST['end_date'])) {
        $start = new DateTime($_POST['start_date']);
        $end = new DateTime($_POST['end_date']);
        $days_stayed = $start->diff($end)->days + 1;
        $days_in_month = cal_days_in_month(CAL_GREGORIAN, $month, $year);
        
        if ($days_stayed > 0 && $days_stayed < $days_in_month) {
            $daily_rate = $total_bill / $days_in_month;
            $total_bill = round($daily_rate * $days_stayed);
            $base_total = $total_bill;
            $rent_display_name = "Tiền phòng (Tính theo ngày: $days_stayed/$days_in_month)";
        }
    }

    $details = [];
    $details[] = [
        "name" => $rent_display_name,
        "price" => floatval($contract['rent_price']),
        "quantity" => 1,
        "unit" => "phòng",
        "subtotal" => $total_bill,
        "type" => "room"
    ];

    while ($s = $services->fetch_assoc()) {
        $name = $s['service_name'];
        $price = floatval($s['service_price']);
        $type = $s['charge_type'];
        $unit = $s['unit'];
        $qty = 1;
        $logic_type = "fixed";

        // Nhận diện loại dịch vụ để Flutter xử lý Realtime
        if (strpos($name, 'Điện') !== false) $logic_type = "electric";
        else if (strpos($name, 'Nước') !== false) $logic_type = "water";

        if ($logic_type == "electric" && $meter) {
            $qty = $meter['new_electric'] - $meter['old_electric'];
        } else if ($logic_type == "water" && $meter) {
            $qty = $meter['new_water'] - $meter['old_water'];
        } else {
            // Tính Qty cho các loại cố định/xe/người
            if ($type == 'per_vehicle') {
                $res = $conn->query("SELECT COUNT(*) as total FROM vehicles v JOIN tenants t ON v.tenant_id = t.id WHERE t.room_id = $room_id");
                $qty = $res->fetch_assoc()['total'] ?? 0;
            } else if ($type == 'per_person') {
                $res = $conn->query("SELECT current_tenants FROM rooms WHERE id = $room_id");
                $qty = $res->fetch_assoc()['current_tenants'] ?? 1;
            }
            $base_total += ($qty * $price); // Cộng vào tiền cố định nếu không phải điện nước
        }

        $sub = $qty * $price;
        
        // Skip if this service is redundant with base rent (Tiền phòng)
        $lowerName = mb_strtolower($name, 'UTF-8');
        if ($lowerName === 'tiền thuê phòng' || $lowerName === 'tiền phòng') {
            continue;
        }

        $total_bill += $sub;

        $details[] = [
            "name" => $name,
            "price" => $price,
            "quantity" => $qty,
            "unit" => $unit,
            "subtotal" => $sub,
            "type" => $logic_type
        ];
    }

    // 4. LƯU HÓA ĐƠN VÀO DATABASE (Sửa từ 'unpaid' thành 'pending' để khớp với ENUM database)
    $stmt = $conn->prepare("INSERT INTO invoices (contract_id, room_id, billing_month, billing_year, total_amount, status) VALUES (?, ?, ?, ?, ?, 'pending')");
    $stmt->bind_param("iiiid", $contract_id, $room_id, $month, $year, $total_bill);
    
    if ($stmt->execute()) {
        $invoice_id = $stmt->insert_id;
        $stmt_detail = $conn->prepare("INSERT INTO invoice_details (invoice_id, service_name, amount) VALUES (?, ?, ?)");
        foreach ($details as $item) {
            $display = $item['name'] . " (SL: " . $item['quantity'] . " " . $item['unit'] . ")";
            $stmt_detail->bind_param("isd", $invoice_id, $display, $item['subtotal']);
            $stmt_detail->execute();
        }
        
        // 📝 GHI LOG TẠO HÓA ĐƠN
        $user_id_creator = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
        $conn->query("INSERT INTO invoice_logs (invoice_id, user_id, old_status, new_status, reason) 
                      VALUES ($invoice_id, $user_id_creator, NULL, 'pending', 'Lập hóa đơn tháng $month/$year - Phòng $room_id')");

        // Trả về dữ liệu để Flutter cập nhật UI ngay lập tức
        echo json_encode([
            "status" => "success",
            "data" => [
                "id" => $invoice_id,
                "meter_id" => $meter['id'] ?? null,
                "old_elec" => $meter['old_electric'] ?? 0,
                "old_water" => $meter['old_water'] ?? 0,
                "base_total_amount" => $base_total,
                "total_amount" => $total_bill,
                "details" => $details
            ]
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => $conn->error]);
    }
}
?>
