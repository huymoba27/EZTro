<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
require_once dirname(__DIR__) . '/helpers/auth_guard.php';
header("Content-Type: application/json; charset=UTF-8");

$house_id = isset($_GET['house_id']) ? intval($_GET['house_id']) : 0;
$year = isset($_GET['year']) ? intval($_GET['year']) : date('Y');
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$role = $_GET['role'] ?? 'landlord';
$managed_house_id = isset($_GET['managed_house_id']) ? intval($_GET['managed_house_id']) : 0;
$auth = qltro_auth_context($conn);
qltro_apply_auth_context($user_id, $role, $managed_house_id, $auth);

// 🎯 Xây dựng bộ lọc theo quyền hạn (Role-based filtering)
$auth_house_ids = [];

if ($role === 'admin') {
    // Admin thấy tất cả - không cần filter mảng ID
} else if ($role === 'manager' && $managed_house_id > 0) {
    $auth_house_ids[] = $managed_house_id;
} else {
    // Landlord: Lấy danh sách ID nhà của họ
    $res_auth = $conn->query("SELECT id FROM houses WHERE user_id = $user_id");
    while($row = $res_auth->fetch_assoc()) {
        $auth_house_ids[] = intval($row['id']);
    }
    // Nếu landlord không có nhà nào, gán ID giả để không ra dữ liệu
    if (empty($auth_house_ids)) $auth_house_ids = [-1];
}

// 🎯 Hàm tiện ích để build WHERE clause
function build_filter($house_col, $house_id, $auth_house_ids) {
    $parts = [];
    if ($house_id > 0) {
        $parts[] = "$house_col = $house_id";
    } else if (!empty($auth_house_ids)) {
        $parts[] = "$house_col IN (" . implode(',', $auth_house_ids) . ")";
    }
    return !empty($parts) ? " AND " . implode(" AND ", $parts) : "";
}

$response = [
    "status" => "success",
    "summary" => [
        "total_houses" => 0,
        "total_rooms" => 0,
        "occupied_rooms" => 0,
        "total_revenue" => 0,
        "total_expense" => 0,
        "net_profit" => 0
    ],
    "revenue_chart" => array_fill(0, 12, 0),
    "expense_chart" => array_fill(0, 12, 0),
    "occupancy_stats" => []
];

// 1. Lấy thông tin nhà và phòng (Occupancy)
$house_where = "WHERE 1=1 " . build_filter("id", $house_id, $auth_house_ids);
$res_houses = $conn->query("SELECT COUNT(*) as count FROM houses $house_where");
$response['summary']['total_houses'] = intval($res_houses->fetch_assoc()['count']);

$room_where = "WHERE 1=1 " . build_filter("house_id", $house_id, $auth_house_ids);
$res_rooms = $conn->query("SELECT COUNT(*) as count FROM rooms $room_where");
$response['summary']['total_rooms'] = intval($res_rooms->fetch_assoc()['count']);

// Đếm phòng đang ở (có hợp đồng active)
$occupied_sql = "SELECT COUNT(DISTINCT r.id) as count 
                FROM rooms r 
                JOIN contracts c ON r.id = c.room_id 
                WHERE c.status = 'active' " . build_filter("r.house_id", $house_id, $auth_house_ids);
$res_occupied = $conn->query($occupied_sql);
$response['summary']['occupied_rooms'] = intval($res_occupied->fetch_assoc()['count']);

// 2. Lấy Doanh thu (Receipts) theo tháng
$rev_sql = "SELECT MONTH(receipt_date) as month, SUM(amount) as total 
            FROM receipts 
            WHERE YEAR(receipt_date) = $year " . build_filter("house_id", $house_id, $auth_house_ids);
$rev_sql .= " GROUP BY MONTH(receipt_date)";

$res_rev = $conn->query($rev_sql);
$total_rev = 0;
if ($res_rev) {
    while ($row = $res_rev->fetch_assoc()) {
        $m = intval($row['month']) - 1;
        $val = floatval($row['total']);
        $response['revenue_chart'][$m] = $val;
        $total_rev += $val;
    }
}
$response['summary']['total_revenue'] = $total_rev;

// 3. Lấy Chi phí (Expenses) theo tháng
$exp_sql = "SELECT MONTH(expense_date) as month, SUM(amount) as total 
            FROM expenses 
            WHERE YEAR(expense_date) = $year " . build_filter("house_id", $house_id, $auth_house_ids);
$exp_sql .= " GROUP BY MONTH(expense_date)";

$res_exp = $conn->query($exp_sql);
$total_exp = 0;
if ($res_exp) {
    while ($row = $res_exp->fetch_assoc()) {
        $m = intval($row['month']) - 1;
        $val = floatval($row['total']);
        $response['expense_chart'][$m] = $val;
        $total_exp += $val;
    }
}
$response['summary']['total_expense'] = $total_exp;
$response['summary']['net_profit'] = $total_rev - $total_exp;

echo json_encode($response);
$conn->close();
?>
