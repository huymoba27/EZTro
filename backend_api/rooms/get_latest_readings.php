<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$room_id = isset($_GET['room_id']) ? (int)$_GET['room_id'] : 0;

if ($room_id <= 0) {
    echo json_encode(["status" => "error", "message" => "Thiếu ID phòng"]);
    exit;
}

$data = [
    "last_electric" => 0,
    "last_water" => 0,
    "source" => "default"
];

// 1. Tìm trong bảng meter_readings (Lịch sử ghi số hàng tháng hoặc lúc khách đi)
$sql_meter = "SELECT new_electric, new_water FROM meter_readings 
              WHERE room_id = $room_id 
              ORDER BY reading_date DESC, id DESC LIMIT 1";
$res_meter = $conn->query($sql_meter);

if ($res_meter && $res_meter->num_rows > 0) {
    $row = $res_meter->fetch_assoc();
    $data['last_electric'] = (int)$row['new_electric'];
    $data['last_water'] = (int)$row['new_water'];
    $data['source'] = "meter_readings";
} else {
    // 2. Nếu chưa từng có bản ghi meter_readings, tìm trong chỉ số đầu của hợp đồng gần nhất
    $sql_contract = "SELECT start_electric_index, start_water_index FROM contracts 
                     WHERE room_id = $room_id 
                     ORDER BY created_at DESC LIMIT 1";
    $res_contract = $conn->query($sql_contract);
    
    if ($res_contract && $res_contract->num_rows > 0) {
        $row = $res_contract->fetch_assoc();
        $data['last_electric'] = (int)$row['start_electric_index'];
        $data['last_water'] = (int)$row['start_water_index'];
        $data['source'] = "contracts";
    }
}

echo json_encode(["status" => "success", "data" => $data]);
?>
