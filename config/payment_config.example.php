<?php
require_once __DIR__ . '/../vendor/autoload.php';

$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->safeLoad();

define('PUBLIC_BASE_URL', $_ENV['PUBLIC_BASE_URL'] ?? 'http://localhost/ql_tro');
define('PAYOS_CLIENT_ID', $_ENV['PAYOS_CLIENT_ID'] ?? '');
define('PAYOS_API_KEY', $_ENV['PAYOS_API_KEY'] ?? '');
define('PAYOS_CHECKSUM_KEY', $_ENV['PAYOS_CHECKSUM_KEY'] ?? '');
?>
