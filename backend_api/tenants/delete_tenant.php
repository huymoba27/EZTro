<?php
include dirname(__DIR__, 2) . '/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Content-Type: application/json; charset=UTF-8");

$tenant_id = isset($_POST['tenant_id']) ? intval($_POST['tenant_id']) : 0;

if ($tenant_id > 0) {
    try {
        // 1. Lấy thông tin khách thuê trước
        $auth = qltro_auth_context($conn);
        qltro_assert_can_access_tenant($conn, $auth, $tenant_id);

        $check_rep = $conn->query("SELECT is_representative, room_id FROM tenants WHERE id = $tenant_id")->fetch_assoc();
        if (!$check_rep) throw new Exception("Khách thuê không tồn tại");
        
        $is_rep = ($check_rep['is_representative'] ?? 0) == 1;
        $room_id = $check_rep['room_id'] ?? 0;

        // 2. Nếu là chủ hộ, kiểm tra nợ của phòng trước khi cho phép xóa (Dùng != 'paid' để an toàn)
        if ($is_rep) {
            $active_contract = $conn->query("SELECT id FROM contracts WHERE room_id = $room_id AND status = 'active' LIMIT 1")->fetch_assoc();
            $active_contract_id = $active_contract ? (int)$active_contract['id'] : 0;
            if ($active_contract_id > 0) {
                echo json_encode(["status" => "error", "message" => "Không thể xóa chủ hộ khi hợp đồng còn hoạt động. Vui lòng dùng luồng thanh lý hoặc xóa hợp đồng nháp/nhầm chưa phát sinh."]);
                exit;
            }
            $debt_check = $active_contract_id > 0
                ? $conn->query("SELECT id FROM invoices WHERE contract_id = $active_contract_id AND status != 'paid'")->num_rows
                : 0;
            if ($debt_check > 0) {
                echo json_encode(["status" => "error", "message" => "Không thể xóa chủ hộ! Phòng này vẫn còn $debt_check hóa đơn chưa thanh toán. Vui lòng xử lý hóa đơn trước."]);
                exit;
            }
        }

        // 3. Nếu không nợ hoặc là thành viên thường -> Tiến hành xóa
        $conn->begin_transaction();

        // Xóa khách thuê (Soft delete)
        $conn->query("UPDATE tenants SET deleted_at = NOW(), status = 'inactive', is_representative = 0 WHERE id = $tenant_id");

        if ($room_id > 0) {
            if ($is_rep) {
                // Nếu là CHỦ HỘ -> Hủy luôn hợp đồng và đuổi tất cả thành viên khác
                $conn->query("UPDATE contracts SET deleted_at = NOW(), status = 'canceled' WHERE room_id = $room_id AND status = 'active'");
                $conn->query("UPDATE tenants SET deleted_at = NOW(), status = 'inactive', is_representative = 0 WHERE room_id = $room_id");
                $conn->query("UPDATE rooms SET current_tenants = 0, status = 'empty' WHERE id = $room_id");
            } else {
                // Nếu là THÀNH VIÊN -> Đếm lại số người thực tế để tránh lệch current_tenants/status
                $active_count = (int)($conn->query("SELECT COUNT(*) as total FROM tenants WHERE room_id = $room_id AND status = 'active' AND deleted_at IS NULL")->fetch_assoc()['total'] ?? 0);
                $room_info = $conn->query("SELECT max_tenants FROM rooms WHERE id = $room_id")->fetch_assoc();
                $max_tenants = (int)($room_info['max_tenants'] ?? 0);
                $new_status = ($active_count <= 0) ? 'empty' : (($active_count >= $max_tenants && $max_tenants > 0) ? 'full' : 'available');
                $conn->query("UPDATE rooms SET current_tenants = $active_count, status = '$new_status' WHERE id = $room_id");
            }
        }

        $conn->commit();
        echo json_encode(["status" => "success", "message" => "Đã xóa khách thuê thành công"]);

    } catch (Exception $e) {
        if ($conn->connect_errno == 0) $conn->rollback();
        echo json_encode(["status" => "error", "message" => "Lỗi: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "ID khách thuê không hợp lệ"]);
}
?>
