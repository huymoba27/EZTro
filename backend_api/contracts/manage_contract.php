<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$action = $_POST['action'] ?? 'update';
$id = isset($_POST['contract_id']) ? (int)$_POST['contract_id'] : (isset($_POST['id']) ? (int)$_POST['id'] : 0);

try {
    if ($id <= 0) throw new Exception("Thiếu ID hợp đồng");

    $auth = qltro_auth_context($conn);
    qltro_assert_can_access_contract($conn, $auth, $id);

    if ($action === 'delete') {
        $contract = $conn->query("SELECT room_id, tenant_id, status FROM contracts WHERE id = $id")->fetch_assoc();
        if (!$contract) throw new Exception("Hợp đồng không tồn tại");
        $room_id = $contract['room_id'];
        $tenant_id = (int)($contract['tenant_id'] ?? 0);

        // Kiểm tra nợ trước khi xóa/thanh lý (Dùng != 'paid' để bao quát mọi trạng thái chưa thu xong)
        $debt_check = $conn->query("SELECT id FROM invoices WHERE contract_id = $id AND status != 'paid'")->num_rows;
        if ($debt_check > 0) {
            echo json_encode(["status" => "error", "message" => "Hợp đồng còn $debt_check hóa đơn chưa thanh toán. Hãy thu tiền hoặc hủy hóa đơn trước khi thanh lý."]);
            exit;
        }

        $history_check = $conn->query("SELECT id FROM invoices WHERE contract_id = $id LIMIT 1")->num_rows
            + $conn->query("SELECT id FROM meter_readings WHERE contract_id = $id LIMIT 1")->num_rows;
        if ($history_check > 0) {
            echo json_encode(["status" => "error", "message" => "Hợp đồng đã có phát sinh chỉ số/hóa đơn, không thể xóa. Vui lòng dùng chức năng thanh lý."]);
            exit;
        }

        $conn->begin_transaction();

        $conn->query("DELETE FROM contract_services WHERE contract_id = $id");
        $conn->query("UPDATE contracts SET deleted_at = NOW(), status = 'canceled' WHERE id = $id");
        
        // Vô hiệu hóa TẤT CẢ khách thuê đang ở trong phòng này (vì hợp đồng đã bị hủy)
        $conn->query("UPDATE tenants SET status = 'inactive', deleted_at = NOW(), is_representative = 0 WHERE room_id = $room_id AND status = 'active'");
        $active_count = (int)($conn->query("SELECT COUNT(*) as total FROM tenants WHERE room_id = $room_id AND status = 'active' AND deleted_at IS NULL")->fetch_assoc()['total'] ?? 0);
        $room_info = $conn->query("SELECT max_tenants FROM rooms WHERE id = $room_id")->fetch_assoc();
        $max_tenants = (int)($room_info['max_tenants'] ?? 0);
        $new_status = ($active_count <= 0) ? 'empty' : (($active_count >= $max_tenants && $max_tenants > 0) ? 'full' : 'available');
        $conn->query("UPDATE rooms SET status = '$new_status', current_tenants = $active_count WHERE id = $room_id");
        
        // 📝 Ghi nhật ký hủy hợp đồng
        $user_id_actor = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
        $conn->query("INSERT INTO contract_logs (contract_id, user_id, action, old_status, new_status, reason) 
                      VALUES ($id, $user_id_actor, 'cancel', 'active', 'canceled', 'Hủy hợp đồng nhập nhầm')");

        $conn->commit();
        echo json_encode(["status" => "success", "message" => "Đã xóa hợp đồng và giải phóng phòng"]);
        exit;
    }

    if ($action === 'update') {
        $price = (float)$_POST['price'];
        $deposit = (float)$_POST['deposit'];
        $payment_day = (int)$_POST['payment_day'];
        $start_elec = (int)$_POST['start_electric'];
        $start_water = (int)$_POST['start_water'];
        $service_ids = isset($_POST['service_ids']) ? json_decode($_POST['service_ids']) : [];
        $user_id = isset($_POST['user_id']) ? (int)$_POST['user_id'] : 0;

        if ($price <= 0) throw new Exception("Giá thuê phải lớn hơn 0");
        if ($deposit < 0) throw new Exception("Tiền cọc không được âm");
        if ($payment_day < 1 || $payment_day > 31) throw new Exception("Ngày thu tiền phải nằm trong khoảng 1-31");
        if ($start_elec < 0 || $start_water < 0) throw new Exception("Chỉ số điện nước đầu kỳ không được âm");

        $has_invoice = $conn->query("SELECT id FROM invoices WHERE contract_id = $id LIMIT 1")->num_rows > 0;
        $has_meter = $conn->query("SELECT id FROM meter_readings WHERE contract_id = $id LIMIT 1")->num_rows > 0;
        if ($has_invoice || $has_meter) {
            throw new Exception("Hợp đồng đã có phát sinh chỉ số hoặc hóa đơn, không thể sửa trực tiếp. Vui lòng xóa phát sinh liên quan hoặc dùng luồng thanh lý/lập hợp đồng mới.");
        }

        // 1. Lấy dữ liệu cũ để so sánh
        $old = $conn->query("SELECT rent_price, deposit_amount, payment_day, start_electric_index, start_water_index FROM contracts WHERE id = $id")->fetch_assoc();
        $changes = [];
        if ($old) {
            $old_price = floatval($old['rent_price']);
            $old_deposit = floatval($old['deposit_amount']);
            $old_payday = (int)$old['payment_day'];
            $old_elec = (int)$old['start_electric_index'];
            $old_water = (int)$old['start_water_index'];

            if (abs($old_price - $price) > 0.01) {
                $changes[] = "Giá thuê: " . number_format($old_price) . " -> " . number_format($price);
            }
            if (abs($old_deposit - $deposit) > 0.01) {
                $changes[] = "Tiền cọc: " . number_format($old_deposit) . " -> " . number_format($deposit);
            }
            if ($old_payday != $payment_day) {
                $changes[] = "Ngày thu: " . $old_payday . " -> " . $payment_day;
            }
            if ($old_elec != $start_elec) {
                $changes[] = "Điện đầu kỳ: " . $old_elec . " -> " . $start_elec;
            }
            if ($old_water != $start_water) {
                $changes[] = "Nước đầu kỳ: " . $old_water . " -> " . $start_water;
            }

            // 🔍 So sánh dịch vụ
            $old_services = [];
            $os_res = $conn->query("SELECT service_id, service_name FROM contract_services WHERE contract_id = $id");
            while($os_row = $os_res->fetch_assoc()) {
                $old_services[$os_row['service_id']] = $os_row['service_name'];
            }

            $new_service_ids = array_map('intval', $service_ids);
            
            // Tìm dịch vụ thêm mới
            foreach ($new_service_ids as $ns_id) {
                if (!isset($old_services[$ns_id])) {
                    $ns_info = $conn->query("SELECT service_name FROM services WHERE id = $ns_id")->fetch_assoc();
                    if ($ns_info) $changes[] = "Thêm DV: " . $ns_info['service_name'];
                }
            }
            // Tìm dịch vụ bị bỏ
            foreach ($old_services as $os_id => $os_name) {
                if (!in_array($os_id, $new_service_ids)) {
                    $changes[] = "Bỏ DV: " . $os_name;
                }
            }
        }
        $change_reason = !empty($changes) ? "Cập nhật HĐ: " . implode(", ", $changes) : "Cập nhật thông tin hợp đồng";

        $conn->begin_transaction();

        // 2. Cập nhật thông tin chính
        $stmt = $conn->prepare("UPDATE contracts SET rent_price = ?, deposit_amount = ?, payment_day = ?, start_electric_index = ?, start_water_index = ? WHERE id = ?");
        $stmt->bind_param("ddiiii", $price, $deposit, $payment_day, $start_elec, $start_water, $id);
        if (!$stmt->execute()) throw new Exception($stmt->error);

        // 3. Cập nhật dịch vụ
        $conn->query("DELETE FROM contract_services WHERE contract_id = $id");
        foreach ($service_ids as $s_id) {
            $service_id = (int)$s_id;
            $s_info = $conn->query("SELECT service_name, price, unit, charge_type FROM services WHERE id = $service_id")->fetch_assoc();
            if ($s_info) {
                $stmt_s = $conn->prepare("INSERT INTO contract_services (contract_id, service_id, service_name, service_price, unit, charge_type) VALUES (?, ?, ?, ?, ?, ?)");
                $stmt_s->bind_param("iisdss", $id, $service_id, $s_info['service_name'], $s_info['price'], $s_info['unit'], $s_info['charge_type']);
                $stmt_s->execute();
            }
        }

        // 4. Ghi Nhật ký chi tiết
        if (!empty($changes)) {
            $log_stmt = $conn->prepare("INSERT INTO contract_logs (contract_id, user_id, action, old_status, new_status, reason) VALUES (?, ?, 'update', 'active', 'active', ?)");
            $log_stmt->bind_param("iis", $id, $user_id, $change_reason);
            $log_stmt->execute();
        }

        $conn->commit();
        echo json_encode(["status" => "success", "message" => "Cập nhật thành công. " . $change_reason]);
        exit;
    }

    if ($action === 'update_status') {
        $status = $_POST['status'] ?? 'active';
        $stmt = $conn->prepare("UPDATE contracts SET status = ? WHERE id = ?");
        $stmt->bind_param("si", $status, $id);
        if ($stmt->execute()) echo json_encode(["status" => "success", "message" => "Cập nhật trạng thái thành công"]);
        else throw new Exception($stmt->error);
        exit;
    }

} catch (Exception $e) {
    $conn->rollback();
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
