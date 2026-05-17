<?php
require_once __DIR__ . '/../vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->safeLoad();

$host = $_ENV['DB_HOST'] ?? 'localhost';
$user = $_ENV['DB_USER'] ?? 'root';
$pass = $_ENV['DB_PASS'] ?? '';
$dbname = $_ENV['DB_NAME'] ?? 'ql_tro';

$conn = new mysqli($host, $user, $pass, $dbname);
mysqli_set_charset($conn, 'utf8mb4');

if ($conn->connect_error) {
    die(json_encode([
        'status' => 'error',
        'message' => 'Ket noi that bai: ' . $conn->connect_error,
    ]));
}
?>
