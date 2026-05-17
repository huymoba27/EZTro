<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/config/config.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conn->set_charset('utf8mb4');

$runId = 'AUTO_TEST_TENANT_LINK_' . date('Ymd_His') . '_' . random_int(1000, 9999);
$baseDir = __DIR__;
$logDir = $baseDir . '/logs';
if (!is_dir($logDir)) {
    mkdir($logDir, 0777, true);
}

$jsonLogPath = $logDir . "/tenant_account_linking_$runId.json";
$mdLogPath = $logDir . "/tenant_account_linking_$runId.md";
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
    'invoice_details' => [],
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
    $placeholders = implode(',', array_fill(0, count($columns), '?'));
    $sql = "INSERT INTO $table (" . implode(',', $columns) . ") VALUES ($placeholders)";
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
    if (empty($tableIds)) return;
    $conn->query("DELETE FROM $table WHERE id IN (" . implode(',', $tableIds) . ")");
}

function cleanup(): void
{
    global $ids;
    deleteIds('incidents', $ids['incidents']);
    deleteIds('deposits', $ids['deposits']);
    deleteIds('invoice_details', $ids['invoice_details']);
    deleteIds('invoices', $ids['invoices']);
    deleteIds('contracts', $ids['contracts']);
    deleteIds('tenants', $ids['tenants']);
    deleteIds('rooms', $ids['rooms']);
    deleteIds('houses', $ids['houses']);
    deleteIds('users', $ids['users']);
}

function scalarValue(string $sql)
{
    global $conn;
    $row = $conn->query($sql)->fetch_row();
    return $row[0] ?? null;
}

function userById(int $userId): array
{
    global $conn;
    return $conn->query("SELECT * FROM users WHERE id = $userId")->fetch_assoc() ?: [];
}

function tenantById(int $tenantId): array
{
    global $conn;
    return $conn->query("SELECT * FROM tenants WHERE id = $tenantId")->fetch_assoc() ?: [];
}

function registerLikeEndpoint(string $username, string $password, string $fullName, string $phone): array
{
    global $conn;

    $stmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR (phone = ? AND phone != '')");
    $stmt->bind_param("ss", $username, $phone);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        return ['status' => 'error', 'message' => 'duplicate_user'];
    }
    $stmt->close();

    $role = 'unassigned';
    $isExistingTenant = false;
    $matchedTenantId = 0;

    if ($phone !== '') {
        $stmtTenant = $conn->prepare("SELECT id FROM tenants WHERE phone = ? AND user_id IS NULL AND status = 'active' AND deleted_at IS NULL ORDER BY id DESC LIMIT 1");
        $stmtTenant->bind_param("s", $phone);
        $stmtTenant->execute();
        $resTenant = $stmtTenant->get_result();
        if ($resTenant->num_rows > 0) {
            $role = 'tenant';
            $isExistingTenant = true;
            $matchedTenantId = (int)$resTenant->fetch_assoc()['id'];
        }
        $stmtTenant->close();
    }

    $hash = password_hash($password, PASSWORD_DEFAULT);
    $stmtInsert = $conn->prepare("INSERT INTO users (username, password, full_name, phone, role) VALUES (?, ?, ?, ?, ?)");
    $stmtInsert->bind_param("sssss", $username, $hash, $fullName, $phone, $role);
    $stmtInsert->execute();
    $userId = (int)$stmtInsert->insert_id;
    $stmtInsert->close();
    global $ids;
    $ids['users'][] = $userId;

    $roomId = null;
    $isRenting = false;
    $displayName = $fullName;

    if ($isExistingTenant) {
        $stmtLink = $conn->prepare("UPDATE tenants SET user_id = ? WHERE id = ?");
        $stmtLink->bind_param("ii", $userId, $matchedTenantId);
        $stmtLink->execute();
        $stmtLink->close();

        $info = $conn->query("SELECT room_id, tenant_name FROM tenants WHERE id = $matchedTenantId AND status = 'active' LIMIT 1")->fetch_assoc();
        if ($info) {
            $roomId = $info['room_id'] ? (int)$info['room_id'] : null;
            $isRenting = $roomId !== null;
            if (!empty($info['tenant_name'])) $displayName = $info['tenant_name'];
        }
    }

    return [
        'status' => 'success',
        'user_id' => $userId,
        'role' => $role,
        'full_name' => $displayName,
        'phone' => $phone,
        'is_renting' => $isRenting,
        'room_id' => $roomId,
        'matched_tenant_id' => $matchedTenantId,
    ];
}

function loginLikeEndpoint(string $usernameOrPhone, string $password): array
{
    global $conn;

    $stmt = $conn->prepare("SELECT id, username, password, role, full_name, managed_house_id, phone FROM users WHERE username = ? OR phone = ?");
    $stmt->bind_param("ss", $usernameOrPhone, $usernameOrPhone);
    $stmt->execute();
    $res = $stmt->get_result();
    if ($res->num_rows === 0) return ['status' => 'error', 'message' => 'not_found'];

    $row = $res->fetch_assoc();
    $stmt->close();

    if (!password_verify($password, $row['password']) && $password !== $row['password']) {
        return ['status' => 'error', 'message' => 'bad_password'];
    }

    $userId = (int)$row['id'];
    if (!empty($row['phone']) && in_array($row['role'], ['tenant', 'unassigned'], true)) {
        $stmtLink = $conn->prepare("SELECT id FROM tenants WHERE phone = ? AND user_id IS NULL AND status = 'active' AND deleted_at IS NULL ORDER BY id DESC LIMIT 1");
        $stmtLink->bind_param("s", $row['phone']);
        $stmtLink->execute();
        $resLink = $stmtLink->get_result();
        if ($resLink->num_rows > 0) {
            $tenantLinkId = (int)$resLink->fetch_assoc()['id'];
            $stmtUpdateTenant = $conn->prepare("UPDATE tenants SET user_id = ? WHERE id = ?");
            $stmtUpdateTenant->bind_param("ii", $userId, $tenantLinkId);
            $stmtUpdateTenant->execute();
            $stmtUpdateTenant->close();
            $conn->query("UPDATE users SET role = 'tenant' WHERE id = $userId AND role = 'unassigned'");
            if ($row['role'] === 'unassigned') $row['role'] = 'tenant';
        }
        $stmtLink->close();
    }

    $isRenting = false;
    $roomId = null;
    $displayName = $row['full_name'];
    $stmtCheck = $conn->prepare("SELECT room_id, tenant_name FROM tenants WHERE user_id = ? AND status = 'active' LIMIT 1");
    $stmtCheck->bind_param("i", $userId);
    $stmtCheck->execute();
    $resCheck = $stmtCheck->get_result();
    if ($resCheck->num_rows > 0) {
        $tenant = $resCheck->fetch_assoc();
        $roomId = $tenant['room_id'] ? (int)$tenant['room_id'] : null;
        $isRenting = $roomId !== null;
        if (!empty($tenant['tenant_name'])) $displayName = $tenant['tenant_name'];
    }
    $stmtCheck->close();

    return [
        'status' => 'success',
        'user_id' => $userId,
        'role' => $row['role'],
        'full_name' => $displayName,
        'phone' => $row['phone'],
        'is_renting' => $isRenting,
        'room_id' => $roomId,
    ];
}

function tenantContractIds(int $userId): array
{
    global $conn;
    $sql = "SELECT c.id
            FROM contracts c
            JOIN rooms r ON c.room_id = r.id
            JOIN houses h ON r.house_id = h.id
            JOIN tenants t ON c.tenant_id = t.id
            WHERE c.deleted_at IS NULL
              AND (t.user_id = $userId OR (t.user_id IS NULL AND t.status = 'active' AND t.deleted_at IS NULL AND t.phone IN (SELECT phone FROM users WHERE id = $userId)))
            ORDER BY c.id DESC";
    $res = $conn->query($sql);
    $out = [];
    while ($row = $res->fetch_assoc()) $out[] = (int)$row['id'];
    return $out;
}

function tenantInvoiceIds(int $userId): array
{
    global $conn;
    $sql = "SELECT i.id
            FROM invoices i
            JOIN rooms r ON i.room_id = r.id
            JOIN houses h ON r.house_id = h.id
            LEFT JOIN contracts ic ON i.contract_id = ic.id
            LEFT JOIN tenants it ON ic.tenant_id = it.id
            WHERE it.user_id = $userId
               OR (it.user_id IS NULL AND it.status = 'active' AND it.deleted_at IS NULL AND it.phone IN (SELECT phone FROM users WHERE id = $userId))
               OR i.contract_id IN (
                    SELECT c2.id
                    FROM contracts c2
                    JOIN tenants t2 ON c2.room_id = t2.room_id
                    WHERE t2.user_id = $userId
                      AND t2.status = 'active'
                      AND c2.status = 'active'
               )
            ORDER BY i.id DESC";
    $res = $conn->query($sql);
    $out = [];
    while ($row = $res->fetch_assoc()) $out[] = (int)$row['id'];
    return $out;
}

function tenantDepositIds(int $userId): array
{
    global $conn;
    $sql = "SELECT d.id
            FROM deposits d
            JOIN houses h ON d.house_id = h.id
            JOIN rooms r ON d.room_id = r.id
            WHERE d.user_id = $userId
               OR (d.user_id IS NULL AND d.customer_phone IN (SELECT phone FROM users WHERE id = $userId))
            ORDER BY d.id DESC";
    $res = $conn->query($sql);
    $out = [];
    while ($row = $res->fetch_assoc()) $out[] = (int)$row['id'];
    return $out;
}

function tenantIncidentIds(int $userId): array
{
    global $conn;
    $sql = "SELECT i.id
            FROM incidents i
            JOIN rooms r ON i.room_id = r.id
            JOIN houses h ON r.house_id = h.id
            JOIN tenants t ON i.tenant_id = t.id
            WHERE i.tenant_id IN (
                SELECT id FROM tenants
                WHERE user_id = $userId
                   OR (user_id IS NULL AND status = 'active' AND deleted_at IS NULL AND phone IN (SELECT phone FROM users WHERE id = $userId))
            )
            ORDER BY i.id DESC";
    $res = $conn->query($sql);
    $out = [];
    while ($row = $res->fetch_assoc()) $out[] = (int)$row['id'];
    return $out;
}

try {
    $landlordId = insertRow('users', [
        'username' => $runId . '_landlord',
        'password' => password_hash('pass123', PASSWORD_DEFAULT),
        'full_name' => 'AUTO TEST Landlord',
        'phone' => '09' . random_int(10000000, 99999999),
        'role' => 'landlord',
    ]);

    $houseId = insertRow('houses', [
        'user_id' => $landlordId,
        'house_name' => $runId . ' House A',
        'city' => 'AUTO',
        'ward' => 'AUTO',
        'address_detail' => 'AUTO TEST',
        'status' => 'active',
    ]);

    $roomId = insertRow('rooms', [
        'house_id' => $houseId,
        'room_name' => $runId . ' Room A',
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
        'tenant_name' => $runId . ' Tenant Active',
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

    $depositManualId = insertRow('deposits', [
        'house_id' => $houseId,
        'room_id' => $roomId,
        'user_id' => null,
        'customer_name' => $runId . ' Tenant Active',
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
        'description' => 'AUTO TEST incident',
        'status' => 'pending',
        'created_at' => date('Y-m-d H:i:s'),
    ]);

    $otherHouseId = insertRow('houses', [
        'user_id' => $landlordId,
        'house_name' => $runId . ' House Other',
        'city' => 'AUTO',
        'ward' => 'AUTO',
        'address_detail' => 'AUTO TEST OTHER',
        'status' => 'active',
    ]);
    $otherRoomId = insertRow('rooms', [
        'house_id' => $otherHouseId,
        'room_name' => $runId . ' Room Other',
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
        'tenant_name' => $runId . ' Tenant Other',
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

    $tc01 = registerLikeEndpoint($runId . '_new_user', 'pass123', 'AUTO TEST New User', '093' . random_int(1000000, 9999999));
    assertCase($tc01['status'] === 'success' && $tc01['role'] === 'unassigned' && $tc01['is_renting'] === false && $tc01['room_id'] === null, 'TC01', 'Dang ky user moi chua co tenant thi khong duoc gan phong', $tc01);

    $tc02 = registerLikeEndpoint($runId . '_linked_user', 'pass123', 'AUTO TEST Linked User', $tenantPhone);
    $linkedTenant = tenantById($tenantId);
    assertCase($tc02['status'] === 'success' && $tc02['role'] === 'tenant' && $tc02['is_renting'] === true && $tc02['room_id'] === $roomId && (int)$linkedTenant['user_id'] === (int)$tc02['user_id'], 'TC02', 'Dang ky bang phone tenant active se link dung tenant', ['response' => $tc02, 'tenant_user_id' => $linkedTenant['user_id'] ?? null]);

    $inactivePhone = '094' . random_int(1000000, 9999999);
    $inactiveTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Tenant Inactive',
        'phone' => $inactivePhone,
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'inactive',
        'deleted_at' => date('Y-m-d H:i:s'),
        'is_representative' => 0,
    ]);
    $tc03 = registerLikeEndpoint($runId . '_inactive_phone_user', 'pass123', 'AUTO TEST Inactive Phone', $inactivePhone);
    $inactiveTenant = tenantById($inactiveTenantId);
    assertCase($tc03['status'] === 'success' && $tc03['role'] === 'unassigned' && $tc03['is_renting'] === false && empty($inactiveTenant['user_id']), 'TC03', 'Dang ky bang phone tenant inactive/deleted khong link', ['response' => $tc03, 'inactive_tenant_user_id' => $inactiveTenant['user_id'] ?? null]);

    $tc04 = registerLikeEndpoint($runId . '_duplicate_phone_user', 'pass123', 'AUTO TEST Duplicate Phone', $tenantPhone);
    assertCase($tc04['status'] === 'error', 'TC04', 'Dang ky phone da co user bi chan trung', $tc04);

    $repairPhone = '095' . random_int(1000000, 9999999);
    $repairTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Tenant Repair',
        'phone' => $repairPhone,
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'active',
        'is_representative' => 0,
    ]);
    $repairUserId = insertRow('users', [
        'username' => $runId . '_repair_user',
        'password' => password_hash('pass123', PASSWORD_DEFAULT),
        'full_name' => 'AUTO TEST Repair User',
        'phone' => $repairPhone,
        'role' => 'unassigned',
    ]);
    $tc05 = loginLikeEndpoint($repairPhone, 'pass123');
    $repairTenant = tenantById($repairTenantId);
    $repairUser = userById($repairUserId);
    assertCase($tc05['status'] === 'success' && $tc05['role'] === 'tenant' && (int)$repairTenant['user_id'] === $repairUserId && $repairUser['role'] === 'tenant', 'TC05', 'Dang nhap repair link va nang role unassigned thanh tenant', ['response' => $tc05, 'tenant_user_id' => $repairTenant['user_id'] ?? null, 'user_role' => $repairUser['role'] ?? null]);

    $managerPhone = '096' . random_int(1000000, 9999999);
    $managerTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Tenant Same Manager Phone',
        'phone' => $managerPhone,
        'gender' => 'Nam',
        'join_date' => date('Y-m-d'),
        'status' => 'active',
        'is_representative' => 0,
    ]);
    $managerId = insertRow('users', [
        'username' => $runId . '_manager',
        'password' => password_hash('pass123', PASSWORD_DEFAULT),
        'full_name' => 'AUTO TEST Manager',
        'phone' => $managerPhone,
        'role' => 'manager',
        'managed_house_id' => $houseId,
    ]);
    $tc06 = loginLikeEndpoint($runId . '_manager', 'pass123');
    $managerTenant = tenantById($managerTenantId);
    $managerUser = userById($managerId);
    assertCase($tc06['status'] === 'success' && $tc06['role'] === 'manager' && empty($managerTenant['user_id']) && $managerUser['role'] === 'manager', 'TC06', 'Dang nhap manager khong bi link nham tenant cung phone', ['response' => $tc06, 'tenant_user_id' => $managerTenant['user_id'] ?? null, 'user_role' => $managerUser['role'] ?? null]);

    $contractIds = tenantContractIds((int)$tc02['user_id']);
    assertCase(in_array($contractId, $contractIds, true) && !in_array($otherContractId, $contractIds, true), 'TC11', 'Tenant chi thay hop dong cua minh', ['visible_contract_ids' => $contractIds, 'own' => $contractId, 'other' => $otherContractId]);

    $invoiceIds = tenantInvoiceIds((int)$tc02['user_id']);
    assertCase(in_array($invoiceId, $invoiceIds, true) && !in_array($otherInvoiceId, $invoiceIds, true), 'TC12', 'Tenant chi thay hoa don cua minh', ['visible_invoice_ids' => $invoiceIds, 'own' => $invoiceId, 'other' => $otherInvoiceId]);

    $depositIds = tenantDepositIds((int)$tc02['user_id']);
    assertCase(in_array($depositManualId, $depositIds, true), 'TC14', 'Tenant thay phieu coc manual chua gan user_id theo phone cua minh', ['visible_deposit_ids' => $depositIds, 'manual_deposit_id' => $depositManualId]);

    $incidentIds = tenantIncidentIds((int)$tc02['user_id']);
    assertCase(in_array($incidentId, $incidentIds, true), 'TC15', 'Tenant thay su co gan voi tenant cua minh', ['visible_incident_ids' => $incidentIds, 'incident_id' => $incidentId]);

    $conn->query("UPDATE contracts SET status = 'ended', end_date = CURDATE() WHERE id = $contractId");
    $conn->query("UPDATE tenants SET status = 'inactive' WHERE id = $tenantId");
    $tc19 = loginLikeEndpoint($tenantPhone, 'pass123');
    assertCase($tc19['status'] === 'success' && $tc19['is_renting'] === false && $tc19['room_id'] === null, 'TC19', 'Tenant cu sau thanh ly khong con duoc xem nhu dang thue active', $tc19);

    $newPhoneAfterEnd = '097' . random_int(1000000, 9999999);
    $newTenantId = insertRow('tenants', [
        'user_id' => null,
        'room_id' => $roomId,
        'tenant_name' => $runId . ' Tenant New After End',
        'phone' => $newPhoneAfterEnd,
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
        'start_electric_index' => 120,
        'start_water_index' => 30,
        'status' => 'active',
    ]);
    $oldTenantContractIdsAfterNew = tenantContractIds((int)$tc02['user_id']);
    assertCase(!in_array($newContractId, $oldTenantContractIdsAfterNew, true), 'TC20', 'Tenant cu khong thay hop dong moi cua phong sau khi da inactive', ['visible_contract_ids' => $oldTenantContractIdsAfterNew, 'new_contract_id' => $newContractId]);

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

    global $events, $stats, $jsonLogPath, $mdLogPath, $runId, $keepData;

    $summary = [
        'run_id' => $runId,
        'created_at' => date('c'),
        'keep_data' => $keepData,
        'stats' => $stats,
        'events' => $events,
    ];
    file_put_contents($jsonLogPath, json_encode($summary, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

    $md = "# Tenant account linking auto test\n\n";
    $md .= "- Run ID: `$runId`\n";
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
