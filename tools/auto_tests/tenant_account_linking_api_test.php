<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/config/config.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conn->set_charset('utf8mb4');

$baseUrl = 'http://localhost/ql_tro/backend_api';
foreach ($argv ?? [] as $arg) {
    if (str_starts_with($arg, '--base-url=')) {
        $baseUrl = rtrim(substr($arg, strlen('--base-url=')), '/');
    }
}

$runId = 'AUTO_API_' . date('Ymd_His') . '_' . random_int(1000, 9999);
$short = 'A' . random_int(100000, 999999);
$logDir = __DIR__ . '/logs';
if (!is_dir($logDir)) mkdir($logDir, 0777, true);

$jsonLogPath = $logDir . "/tenant_account_linking_api_$runId.json";
$mdLogPath = $logDir . "/tenant_account_linking_api_$runId.md";
$keepData = in_array('--keep-data', $argv ?? [], true);

$events = [];
$stats = ['passed' => 0, 'failed' => 0];
$ids = [
    'users' => [],
    'houses' => [],
    'rooms' => [],
    'tenants' => [],
    'contracts' => [],
    'invoices' => [],
    'deposits' => [],
    'incidents' => [],
];

function logEvent(string $status, string $case, string $message, array $context = []): void
{
    global $events, $stats;
    $events[] = [
        'time' => date('c'),
        'status' => $status,
        'case' => $case,
        'message' => $message,
        'context' => $context,
    ];
    if ($status === 'PASS') $stats['passed']++;
    if ($status === 'FAIL') $stats['failed']++;
    echo "[$status] $case - $message\n";
}

function assertCase(bool $condition, string $case, string $message, array $context = []): void
{
    logEvent($condition ? 'PASS' : 'FAIL', $case, $message, $context);
}

function insertRow(string $table, array $data): int
{
    global $conn, $ids;
    $columns = array_keys($data);
    $sql = "INSERT INTO $table (" . implode(',', $columns) . ") VALUES (" . implode(',', array_fill(0, count($columns), '?')) . ")";
    $stmt = $conn->prepare($sql);

    $types = '';
    $values = [];
    foreach ($data as $value) {
        if (is_int($value)) $types .= 'i';
        elseif (is_float($value)) $types .= 'd';
        else $types .= 's';
        $values[] = $value;
    }

    $stmt->bind_param($types, ...$values);
    $stmt->execute();
    $id = (int)$stmt->insert_id;
    $stmt->close();
    if ($id > 0 && isset($ids[$table])) $ids[$table][] = $id;
    return $id;
}

function deleteIds(string $table, array $tableIds): void
{
    global $conn;
    $tableIds = array_values(array_filter(array_map('intval', $tableIds)));
    if (!$tableIds) return;
    $conn->query("DELETE FROM $table WHERE id IN (" . implode(',', $tableIds) . ")");
}

function cleanup(): void
{
    global $ids;
    deleteIds('incidents', $ids['incidents']);
    deleteIds('deposits', $ids['deposits']);
    deleteIds('invoices', $ids['invoices']);
    deleteIds('contracts', $ids['contracts']);
    deleteIds('tenants', $ids['tenants']);
    deleteIds('rooms', $ids['rooms']);
    deleteIds('houses', $ids['houses']);
    deleteIds('users', $ids['users']);
}

function apiRequest(string $method, string $path, array $params = []): array
{
    global $baseUrl;
    $url = $baseUrl . '/' . ltrim($path, '/');
    if ($method === 'GET' && $params) {
        $url .= '?' . http_build_query($params);
    }

    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 15);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['ngrok-skip-browser-warning: true']);
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($params));
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Content-Type: application/x-www-form-urlencoded',
            'ngrok-skip-browser-warning: true',
        ]);
    }
    $raw = curl_exec($ch);
    $err = curl_error($ch);
    $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    $json = json_decode((string)$raw, true);
    return [
        'http_code' => $code,
        'error' => $err,
        'raw' => $raw,
        'json' => is_array($json) ? $json : null,
    ];
}

function tenantById(int $tenantId): array
{
    global $conn;
    return $conn->query("SELECT * FROM tenants WHERE id = $tenantId")->fetch_assoc() ?: [];
}

function userById(int $userId): array
{
    global $conn;
    return $conn->query("SELECT * FROM users WHERE id = $userId")->fetch_assoc() ?: [];
}

function trackUserFromResponse(?array $json): void
{
    global $ids;
    if (isset($json['user_id']) && (int)$json['user_id'] > 0) {
        $ids['users'][] = (int)$json['user_id'];
    }
}

function responseIds(array $response): array
{
    $data = $response['json']['data'] ?? [];
    if (!is_array($data)) return [];
    if (isset($data['id'])) return [(int)$data['id']];
    $ids = [];
    foreach ($data as $row) {
        if (is_array($row) && isset($row['id'])) $ids[] = (int)$row['id'];
    }
    return $ids;
}

try {
    $landlordId = insertRow('users', [
        'username' => $short . '_landlord',
        'password' => password_hash('pass123', PASSWORD_DEFAULT),
        'full_name' => 'AUTO API Landlord',
        'phone' => '08' . random_int(10000000, 99999999),
        'role' => 'landlord',
    ]);

    $houseId = insertRow('houses', [
        'user_id' => $landlordId,
        'house_name' => $runId . ' House',
        'city' => 'AUTO',
        'ward' => 'AUTO',
        'address_detail' => 'AUTO TEST API',
        'status' => 'active',
    ]);

    $roomId = insertRow('rooms', [
        'house_id' => $houseId,
        'room_name' => $runId . ' Room',
        'price' => 2500000.0,
        'deposit' => 1000000.0,
        'area' => 20.0,
        'max_tenants' => 2,
        'current_tenants' => 1,
        'status' => 'available',
    ]);

    $tenantPhone = '091' . random_int(1000000, 9999999);
    $tenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Tenant',
        'phone' => $tenantPhone,
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'active',
        'is_representative' => 1,
    ]);

    $contractId = insertRow('contracts', [
        'room_id' => $roomId,
        'tenant_id' => $tenantId,
        'start_date' => date('Y-m-d'),
        'end_date' => date('Y-m-d', strtotime('+6 months')),
        'rent_price' => 2500000.0,
        'deposit_amount' => 1000000.0,
        'payment_day' => 5,
        'start_electric_index' => 100,
        'start_water_index' => 20,
        'status' => 'active',
    ]);

    $invoiceId = insertRow('invoices', [
        'contract_id' => $contractId,
        'room_id' => $roomId,
        'billing_month' => (int)date('n'),
        'billing_year' => (int)date('Y'),
        'total_amount' => 2600000.0,
        'status' => 'pending',
    ]);

    $depositId = insertRow('deposits', [
        'house_id' => $houseId,
        'room_id' => $roomId,
        'user_id' => null,
        'customer_name' => $runId . ' Tenant',
        'customer_phone' => $tenantPhone,
        'deposit_amount' => 1000000.0,
        'deposit_date' => date('Y-m-d'),
        'expected_move_in_date' => date('Y-m-d', strtotime('+7 days')),
        'status' => 'pending',
    ]);

    $incidentId = insertRow('incidents', [
        'room_id' => $roomId,
        'tenant_id' => $tenantId,
        'title' => $runId . ' Incident',
        'description' => 'AUTO API incident',
        'status' => 'pending',
        'created_at' => date('Y-m-d H:i:s'),
    ]);

    $otherHouseId = insertRow('houses', [
        'user_id' => $landlordId,
        'house_name' => $runId . ' Other House',
        'city' => 'AUTO',
        'ward' => 'AUTO',
        'address_detail' => 'AUTO TEST API OTHER',
        'status' => 'active',
    ]);
    $otherRoomId = insertRow('rooms', [
        'house_id' => $otherHouseId,
        'room_name' => $runId . ' Other Room',
        'price' => 3000000.0,
        'deposit' => 1000000.0,
        'area' => 22.0,
        'max_tenants' => 2,
        'current_tenants' => 1,
        'status' => 'available',
    ]);
    $otherTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $otherRoomId,
        'tenant_name' => $runId . ' Other Tenant',
        'phone' => '092' . random_int(1000000, 9999999),
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'active',
        'is_representative' => 1,
    ]);
    $otherContractId = insertRow('contracts', [
        'room_id' => $otherRoomId,
        'tenant_id' => $otherTenantId,
        'start_date' => date('Y-m-d'),
        'end_date' => date('Y-m-d', strtotime('+6 months')),
        'rent_price' => 3000000.0,
        'deposit_amount' => 1000000.0,
        'payment_day' => 5,
        'start_electric_index' => 10,
        'start_water_index' => 5,
        'status' => 'active',
    ]);
    $otherInvoiceId = insertRow('invoices', [
        'contract_id' => $otherContractId,
        'room_id' => $otherRoomId,
        'billing_month' => (int)date('n'),
        'billing_year' => (int)date('Y'),
        'total_amount' => 3000000.0,
        'status' => 'pending',
    ]);

    $tc01 = apiRequest('POST', 'auth/register.php', [
        'username' => $short . '_new',
        'password' => 'pass123',
        'full_name' => 'AUTO API New',
        'phone' => '093' . random_int(1000000, 9999999),
    ]);
    trackUserFromResponse($tc01['json']);
    assertCase(($tc01['json']['status'] ?? '') === 'success' && ($tc01['json']['role'] ?? '') === 'unassigned' && ($tc01['json']['is_renting'] ?? true) === false, 'API-TC01', 'API register user moi khong co tenant tra ve unassigned', $tc01['json'] ?? $tc01);

    $tc02 = apiRequest('POST', 'auth/register.php', [
        'username' => $short . '_linked',
        'password' => 'pass123',
        'full_name' => 'AUTO API Linked',
        'phone' => $tenantPhone,
    ]);
    trackUserFromResponse($tc02['json']);
    $linkedTenant = tenantById($tenantId);
    $linkedUserId = (int)($tc02['json']['user_id'] ?? 0);
    assertCase(($tc02['json']['status'] ?? '') === 'success' && ($tc02['json']['role'] ?? '') === 'tenant' && (int)($tc02['json']['room_id'] ?? 0) === $roomId && (int)($linkedTenant['user_id'] ?? 0) === $linkedUserId, 'API-TC02', 'API register phone tenant active link dung tenants.user_id', ['response' => $tc02['json'], 'tenant_user_id' => $linkedTenant['user_id'] ?? null]);

    $inactivePhone = '094' . random_int(1000000, 9999999);
    $inactiveTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Inactive Tenant',
        'phone' => $inactivePhone,
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'inactive',
        'deleted_at' => date('Y-m-d H:i:s'),
        'is_representative' => 0,
    ]);
    $tc03 = apiRequest('POST', 'auth/register.php', [
        'username' => $short . '_inactive',
        'password' => 'pass123',
        'full_name' => 'AUTO API Inactive',
        'phone' => $inactivePhone,
    ]);
    trackUserFromResponse($tc03['json']);
    $inactiveTenant = tenantById($inactiveTenantId);
    assertCase(($tc03['json']['status'] ?? '') === 'success' && ($tc03['json']['role'] ?? '') === 'unassigned' && empty($inactiveTenant['user_id']), 'API-TC03', 'API register phone tenant inactive khong link', ['response' => $tc03['json'], 'tenant_user_id' => $inactiveTenant['user_id'] ?? null]);

    $tc04 = apiRequest('POST', 'auth/register.php', [
        'username' => $short . '_dup',
        'password' => 'pass123',
        'full_name' => 'AUTO API Duplicate',
        'phone' => $tenantPhone,
    ]);
    assertCase(($tc04['json']['status'] ?? '') === 'error', 'API-TC04', 'API register phone da co user bi chan', $tc04['json'] ?? $tc04);

    $repairPhone = '095' . random_int(1000000, 9999999);
    $repairTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Repair Tenant',
        'phone' => $repairPhone,
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'active',
        'is_representative' => 0,
    ]);
    $repairUserId = insertRow('users', [
        'username' => $short . '_repair',
        'password' => password_hash('pass123', PASSWORD_DEFAULT),
        'full_name' => 'AUTO API Repair',
        'phone' => $repairPhone,
        'role' => 'unassigned',
    ]);
    $tc05 = apiRequest('POST', 'auth/login.php', [
        'username' => $repairPhone,
        'password' => 'pass123',
    ]);
    $repairTenant = tenantById($repairTenantId);
    $repairUser = userById($repairUserId);
    assertCase(($tc05['json']['status'] ?? '') === 'success' && ($tc05['json']['role'] ?? '') === 'tenant' && (int)($repairTenant['user_id'] ?? 0) === $repairUserId && ($repairUser['role'] ?? '') === 'tenant', 'API-TC05', 'API login repair link va nang role tenant', ['response' => $tc05['json'], 'tenant_user_id' => $repairTenant['user_id'] ?? null, 'user_role' => $repairUser['role'] ?? null]);

    $managerPhone = '096' . random_int(1000000, 9999999);
    $managerTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Same Manager Phone',
        'phone' => $managerPhone,
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'active',
        'is_representative' => 0,
    ]);
    $managerId = insertRow('users', [
        'username' => $short . '_manager',
        'password' => password_hash('pass123', PASSWORD_DEFAULT),
        'full_name' => 'AUTO API Manager',
        'phone' => $managerPhone,
        'role' => 'manager',
        'managed_house_id' => $houseId,
    ]);
    $tc06 = apiRequest('POST', 'auth/login.php', [
        'username' => $managerPhone,
        'password' => 'pass123',
    ]);
    $managerTenant = tenantById($managerTenantId);
    $managerUser = userById($managerId);
    assertCase(($tc06['json']['status'] ?? '') === 'success' && ($tc06['json']['role'] ?? '') === 'manager' && empty($managerTenant['user_id']) && ($managerUser['role'] ?? '') === 'manager', 'API-TC06', 'API login manager khong link nham tenant cung phone', ['response' => $tc06['json'], 'tenant_user_id' => $managerTenant['user_id'] ?? null]);

    $contracts = apiRequest('GET', 'contracts/get_contracts.php', [
        'user_id' => $linkedUserId,
        'role' => 'admin',
        'managed_house_id' => 999999,
    ]);
    $contractIds = responseIds($contracts);
    assertCase(in_array($contractId, $contractIds, true) && !in_array($otherContractId, $contractIds, true), 'API-TC11', 'API get_contracts khong bi role/managed_house_id fake danh lua', ['ids' => $contractIds, 'own' => $contractId, 'other' => $otherContractId, 'response' => $contracts['json']]);

    $invoices = apiRequest('GET', 'invoice/get_invoices.php', [
        'user_id' => $linkedUserId,
        'role' => 'admin',
        'managed_house_id' => 999999,
    ]);
    $invoiceIds = responseIds($invoices);
    assertCase(in_array($invoiceId, $invoiceIds, true) && !in_array($otherInvoiceId, $invoiceIds, true), 'API-TC12', 'API get_invoices tenant chi thay hoa don cua minh', ['ids' => $invoiceIds, 'own' => $invoiceId, 'other' => $otherInvoiceId, 'response' => $invoices['json']]);

    $deposits = apiRequest('GET', 'deposits/get_deposits.php', [
        'user_id' => $linkedUserId,
        'role' => 'tenant',
    ]);
    $depositIds = responseIds($deposits);
    assertCase(in_array($depositId, $depositIds, true), 'API-TC14', 'API get_deposits tenant thay coc manual theo phone', ['ids' => $depositIds, 'deposit' => $depositId, 'response' => $deposits['json']]);

    $incidents = apiRequest('GET', 'incidents/get_incidents.php', [
        'user_id' => $linkedUserId,
        'role' => 'tenant',
    ]);
    $incidentIds = responseIds($incidents);
    assertCase(in_array($incidentId, $incidentIds, true), 'API-TC15', 'API get_incidents tenant thay su co cua minh', ['ids' => $incidentIds, 'incident' => $incidentId, 'response' => $incidents['json']]);

    $conn->query("UPDATE contracts SET status = 'ended', end_date = CURDATE() WHERE id = $contractId");
    $conn->query("UPDATE tenants SET status = 'inactive' WHERE id = $tenantId");
    $tc19 = apiRequest('POST', 'auth/login.php', [
        'username' => $tenantPhone,
        'password' => 'pass123',
    ]);
    assertCase(($tc19['json']['status'] ?? '') === 'success' && ($tc19['json']['is_renting'] ?? true) === false && ($tc19['json']['room_id'] ?? null) === null, 'API-TC19', 'API login tenant cu sau thanh ly khong con is_renting', $tc19['json'] ?? $tc19);

    $newTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' New Tenant After End',
        'phone' => '097' . random_int(1000000, 9999999),
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'active',
        'is_representative' => 1,
    ]);
    $newContractId = insertRow('contracts', [
        'room_id' => $roomId,
        'tenant_id' => $newTenantId,
        'start_date' => date('Y-m-d'),
        'end_date' => date('Y-m-d', strtotime('+6 months')),
        'rent_price' => 2700000.0,
        'deposit_amount' => 1000000.0,
        'payment_day' => 5,
        'start_electric_index' => 130,
        'start_water_index' => 33,
        'status' => 'active',
    ]);
    $contractsAfterNew = apiRequest('GET', 'contracts/get_contracts.php', [
        'user_id' => $linkedUserId,
        'role' => 'tenant',
    ]);
    $contractIdsAfterNew = responseIds($contractsAfterNew);
    assertCase(!in_array($newContractId, $contractIdsAfterNew, true), 'API-TC20', 'API tenant cu khong thay hop dong moi cua phong', ['ids' => $contractIdsAfterNew, 'new_contract' => $newContractId, 'response' => $contractsAfterNew['json']]);

} catch (Throwable $e) {
    logEvent('FAIL', 'UNCAUGHT', $e->getMessage(), ['trace' => $e->getTraceAsString()]);
} finally {
    if (!$keepData) {
        try {
            cleanup();
        } catch (Throwable $cleanupError) {
            logEvent('FAIL', 'CLEANUP', $cleanupError->getMessage());
        }
    }

    $summary = [
        'run_id' => $runId,
        'base_url' => $baseUrl,
        'created_at' => date('c'),
        'keep_data' => $keepData,
        'stats' => $stats,
        'events' => $events,
    ];
    file_put_contents($jsonLogPath, json_encode($summary, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

    $md = "# Tenant account linking API auto test\n\n";
    $md .= "- Run ID: `$runId`\n";
    $md .= "- Base URL: `$baseUrl`\n";
    $md .= "- Passed: {$stats['passed']}\n";
    $md .= "- Failed: {$stats['failed']}\n";
    $md .= "- Keep data: " . ($keepData ? 'yes' : 'no') . "\n\n";
    $md .= "| Status | Case | Message |\n|---|---|---|\n";
    foreach ($events as $event) {
        $md .= "| {$event['status']} | {$event['case']} | " . str_replace('|', '\\|', $event['message']) . " |\n";
    }
    file_put_contents($mdLogPath, $md);

    echo "\nLog JSON: $jsonLogPath\n";
    echo "Log MD:   $mdLogPath\n";
    exit($stats['failed'] > 0 ? 1 : 0);
}
