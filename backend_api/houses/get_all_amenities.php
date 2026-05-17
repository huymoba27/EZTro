<?php
include $_SERVER['DOCUMENT_ROOT'] . '/ql_tro/config/config.php';
$sql = "SELECT * FROM amenities";
$result = $conn->query($sql);
$data = [];
while($row = $result->fetch_assoc()) {
    $data[] = $row;
}
echo json_encode($data);
?>