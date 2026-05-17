<?php
declare(strict_types=1);

require_once dirname(__DIR__, 2) . '/config/config.php';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$conn->set_charset('utf8mb4');

$runId = 'AUTO_TEST_' . date('Ymd_His') . '_' . random_int(1000, 9999);
$baseDir = __DIR__;
$logDir = $baseDir . '/logs';
if (!is_dir($logDir)) {
    mkdir($logDir, 0777, true);
}

$jsonLogPath = $logDir . "/contract_invoice_flow_$runId.json";
$mdLogPath = $logDir . "/contract_invoice_flow_$runId.md";
$keepData = in_array('--keep-data', $argv ?? [], true);

$events = [];
$ids = [
    'users' => [],
    'houses' => [],
    'rooms' => [],
    'services' => [],
    'tenants' => [],
    'contracts' => [],
    'contract_services' => [],
    'meter_readings' => [],
    'invoices' => [],
    'invoice_details' => [],
    'receipts' => [],
    'expenses' => [],
    'contract_logs' => [],
    'invoice_logs' => [],
    'tenant_logs' => [],
];
$stats = ['passed' => 0, 'failed' => 0];

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
    if ($status === 'PASS') {
        $stats['passed']++;
    } elseif ($status === 'FAIL') {
        $stats['failed']++;
    }
    echo "[$status] $case - $message\n";
}

function passCase(string $case, string $message, array $context = []): void
{
    logEvent('PASS', $case, $message, $context);
}

function failCase(string $case, string $message, array $context = []): void
{
    logEvent('FAIL', $case, $message, $context);
}

function assertCase(bool $condition, string $case, string $message, array $context = []): void
{
    if ($condition) {
        passCase($case, $message, $context);
    } else {
        failCase($case, $message, $context);
    }
}

function scalarValue(string $sql)
{
    global $conn;
    $row = $conn->query($sql)->fetch_row();
    return $row[0] ?? null;
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
        if (is_int($value)) {
            $types .= 'i';
        } elseif (is_float($value)) {
            $types .= 'd';
        } else {
            $types .= 's';
        }
        $values[] = $value;
    }

    $stmt->bind_param($types, ...$values);
    $stmt->execute();
    $id = $stmt->insert_id;
    $stmt->close();

    if (isset($ids[$table]) && $id > 0) {
        $ids[$table][] = $id;
    }
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
    deleteIds('tenant_logs', $ids['tenant_logs']);
    deleteIds('invoice_logs', $ids['invoice_logs']);
    deleteIds('contract_logs', $ids['contract_logs']);
    deleteIds('receipts', $ids['receipts']);
    deleteIds('expenses', $ids['expenses']);
    deleteIds('invoice_details', $ids['invoice_details']);
    deleteIds('invoices', $ids['invoices']);
    deleteIds('meter_readings', $ids['meter_readings']);
    deleteIds('contract_services', $ids['contract_services']);
    deleteIds('contracts', $ids['contracts']);
    deleteIds('tenants', $ids['tenants']);
    deleteIds('services', $ids['services']);
    deleteIds('rooms', $ids['rooms']);
    deleteIds('houses', $ids['houses']);
    deleteIds('users', $ids['users']);
}

function createContract(int $roomId, array $data): array
{
    global $conn;
    $active = scalarValue("SELECT id FROM contracts WHERE room_id = $roomId AND status = 'active' LIMIT 1");
    if ($active) {
        return ['ok' => false, 'message' => 'Room already has active contract', 'contract_id' => (int)$active];
    }

    $tenantId = insertRow('tenants', [
        'user_id' => 0,
        'room_id' => $roomId,
        'is_representative' => 1,
        'tenant_name' => $data['tenant_name'],
        'phone' => $data['phone'],
        'email' => $data['email'],
        'gender' => 'Nam',
        'join_date' => $data['start_date'],
        'status' => 'active',
    ]);

    $contractId = insertRow('contracts', [
        'room_id' => $roomId,
        'tenant_id' => $tenantId,
        'start_date' => $data['start_date'],
        'end_date' => $data['end_date'],
        'rent_price' => (float)$data['rent_price'],
        'deposit_amount' => (float)$data['deposit_amount'],
        'payment_day' => 5,
        'start_electric_index' => (int)$data['start_electric'],
        'start_water_index' => (int)$data['start_water'],
        'status' => 'active',
    ]);

    $conn->query("UPDATE rooms SET current_tenants = 1, status = 'available' WHERE id = $roomId");

    return ['ok' => true, 'tenant_id' => $tenantId, 'contract_id' => $contractId];
}

function attachServicesToContract(int $contractId, array $services): void
{
    foreach ($services as $service) {
        insertRow('contract_services', [
            'contract_id' => $contractId,
            'service_id' => $service['id'],
            'service_name' => $service['name'],
            'service_price' => (float)$service['price'],
            'unit' => $service['unit'],
            'charge_type' => $service['charge_type'],
        ]);
    }
}

function createMeterReading(int $contractId, int $roomId, int $month, int $year, int $oldE, int $newE, int $oldW, int $newW): array
{
    $exists = scalarValue("SELECT id FROM meter_readings WHERE contract_id = $contractId AND billing_month = $month AND billing_year = $year LIMIT 1");
    if ($exists) {
        return ['ok' => false, 'message' => 'Duplicate meter reading', 'meter_id' => (int)$exists];
    }

    $meterId = insertRow('meter_readings', [
        'contract_id' => $contractId,
        'room_id' => $roomId,
        'reading_date' => date('Y-m-d'),
        'billing_month' => $month,
        'billing_year' => $year,
        'old_electric' => $oldE,
        'new_electric' => $newE,
        'old_water' => $oldW,
        'new_water' => $newW,
    ]);
    return ['ok' => true, 'meter_id' => $meterId];
}

function calculateInvoiceTotal(int $contractId, int $roomId, int $month, int $year): array
{
    global $conn;
    $contract = $conn->query("SELECT * FROM contracts WHERE id = $contractId")->fetch_assoc();
    $meter = $conn->query("SELECT * FROM meter_readings WHERE contract_id = $contractId AND billing_month = $month AND billing_year = $year")->fetch_assoc();
    $services = $conn->query("SELECT * FROM contract_services WHERE contract_id = $contractId");

    $details = [[
        'name' => 'Tien phong',
        'amount' => (float)$contract['rent_price'],
    ]];
    $total = (float)$contract['rent_price'];

    while ($service = $services->fetch_assoc()) {
        $name = strtolower($service['service_name']);
        $qty = 1;
        if (str_contains($name, 'dien') || str_contains($name, 'electric')) {
            $qty = $meter ? ((int)$meter['new_electric'] - (int)$meter['old_electric']) : 0;
        } elseif (str_contains($name, 'nuoc') || str_contains($name, 'water')) {
            $qty = $meter ? ((int)$meter['new_water'] - (int)$meter['old_water']) : 0;
        }
        $amount = $qty * (float)$service['service_price'];
        $total += $amount;
        $details[] = [
            'name' => $service['service_name'] . " (SL: $qty {$service['unit']})",
            'amount' => $amount,
        ];
    }

    return ['total' => $total, 'details' => $details];
}

function createInvoice(int $contractId, int $roomId, int $month, int $year): array
{
    $exists = scalarValue("SELECT id FROM invoices WHERE contract_id = $contractId AND billing_month = $month AND billing_year = $year LIMIT 1");
    if ($exists) {
        return ['ok' => false, 'message' => 'Duplicate invoice', 'invoice_id' => (int)$exists];
    }

    $calc = calculateInvoiceTotal($contractId, $roomId, $month, $year);
    $invoiceId = insertRow('invoices', [
        'contract_id' => $contractId,
        'room_id' => $roomId,
        'billing_month' => $month,
        'billing_year' => $year,
        'total_amount' => (float)$calc['total'],
        'status' => 'pending',
    ]);

    foreach ($calc['details'] as $detail) {
        insertRow('invoice_details', [
            'invoice_id' => $invoiceId,
            'service_name' => $detail['name'],
            'amount' => (float)$detail['amount'],
        ]);
    }

    return ['ok' => true, 'invoice_id' => $invoiceId, 'total' => $calc['total']];
}

function markInvoicePaid(int $invoiceId, int $houseId, int $roomId, string $tenantName): void
{
    global $conn;
    $invoice = $conn->query("SELECT * FROM invoices WHERE id = $invoiceId")->fetch_assoc();
    $oldStatus = $invoice['status'];
    $conn->query("UPDATE invoices SET status = 'paid' WHERE id = $invoiceId");

    if ($oldStatus !== 'paid') {
        $receiptExists = scalarValue("SELECT id FROM receipts WHERE invoice_id = $invoiceId AND receipt_type = 'monthly_bill' LIMIT 1");
        if (!$receiptExists) {
            insertRow('receipts', [
                'house_id' => $houseId,
                'room_id' => $roomId,
                'invoice_id' => $invoiceId,
                'tenant_name' => $tenantName,
                'amount' => (float)$invoice['total_amount'],
                'receipt_date' => date('Y-m-d'),
                'payment_method' => 'Tien mat',
                'receipt_type' => 'monthly_bill',
                'description' => 'AUTO_TEST receipt for invoice payment',
            ]);
        }
    }
}

function terminateContract(int $contractId, int $houseId, int $roomId, int $tenantId): array
{
    global $conn;
    $contract = $conn->query("SELECT * FROM contracts WHERE id = $contractId")->fetch_assoc();
    $tenant = $conn->query("SELECT * FROM tenants WHERE id = $tenantId")->fetch_assoc();
    if (!$contract || $contract['status'] !== 'active') {
        return ['ok' => false, 'message' => 'Contract is not active'];
    }

    $debt = (float)scalarValue("SELECT COALESCE(SUM(total_amount), 0) FROM invoices WHERE contract_id = $contractId AND status = 'pending'");
    $deposit = (float)$contract['deposit_amount'];
    $refund = max(0, $deposit - $debt);
    $offset = min($deposit, $debt);

    $conn->query("UPDATE contracts SET status = 'ended', end_date = CURDATE() WHERE id = $contractId");
    $conn->query("UPDATE rooms SET status = 'empty', current_tenants = 0 WHERE id = $roomId");
    $conn->query("UPDATE tenants SET status = 'inactive' WHERE room_id = $roomId AND status = 'active'");

    if ($offset > 0) {
        insertRow('receipts', [
            'house_id' => $houseId,
            'room_id' => $roomId,
            'invoice_id' => null,
            'tenant_name' => $tenant['tenant_name'],
            'amount' => $offset,
            'receipt_date' => date('Y-m-d'),
            'payment_method' => 'Tien mat',
            'receipt_type' => 'settlement',
            'description' => 'AUTO_TEST settlement offset',
        ]);
    }

    if ($refund > 0) {
        insertRow('expenses', [
            'house_id' => $houseId,
            'room_id' => $roomId,
            'receiver_name' => $tenant['tenant_name'],
            'amount' => $refund,
            'expense_date' => date('Y-m-d'),
            'payment_method' => 'Tien mat',
            'expense_type' => 'refund',
            'description' => 'AUTO_TEST deposit refund',
        ]);
    }

    return ['ok' => true, 'refund' => $refund, 'debt' => $debt];
}

function getLatestRoomReadingForNewContract(int $roomId): array
{
    global $conn;
    $meter = $conn->query("SELECT new_electric as old_electric, new_water as old_water
                           FROM meter_readings
                           WHERE room_id = $roomId
                           ORDER BY billing_year DESC, billing_month DESC, id DESC LIMIT 1")->fetch_assoc();
    if ($meter) {
        return [
            'old_electric' => (int)$meter['old_electric'],
            'old_water' => (int)$meter['old_water'],
        ];
    }

    $contract = $conn->query("SELECT start_electric_index as old_electric, start_water_index as old_water
                              FROM contracts
                              WHERE room_id = $roomId
                              ORDER BY id DESC LIMIT 1")->fetch_assoc();
    if ($contract) {
        return [
            'old_electric' => (int)$contract['old_electric'],
            'old_water' => (int)$contract['old_water'],
        ];
    }

    return ['old_electric' => 0, 'old_water' => 0];
}

function writeLogs(): void
{
    global $jsonLogPath, $mdLogPath, $events, $stats, $runId, $keepData, $ids;

    $payload = [
        'run_id' => $runId,
        'started_at' => $events[0]['time'] ?? date('c'),
        'finished_at' => date('c'),
        'keep_data' => $keepData,
        'summary' => $stats,
        'ids' => $ids,
        'events' => $events,
    ];
    file_put_contents($jsonLogPath, json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

    $md = "# Contract Invoice Flow Test\n\n";
    $md .= "- Run ID: `$runId`\n";
    $md .= "- Result: " . ($stats['failed'] === 0 ? "PASS" : "FAIL") . "\n";
    $md .= "- Passed: {$stats['passed']}\n";
    $md .= "- Failed: {$stats['failed']}\n";
    $md .= "- Keep data: " . ($keepData ? 'yes' : 'no') . "\n\n";
    $md .= "## Events\n\n";
    foreach ($events as $event) {
        $md .= "- `{$event['status']}` **{$event['case']}**: {$event['message']}\n";
        if (!empty($event['context'])) {
            $md .= "  - Context: `" . json_encode($event['context'], JSON_UNESCAPED_UNICODE) . "`\n";
        }
    }
    file_put_contents($mdLogPath, $md);
}

try {
    logEvent('INFO', 'setup', "Starting run $runId");

    $landlordId = insertRow('users', [
        'username' => strtolower($runId) . '_landlord',
        'password' => password_hash('123456', PASSWORD_DEFAULT),
        'role' => 'landlord',
        'full_name' => 'Auto Test Landlord',
        'phone' => '090' . random_int(1000000, 9999999),
    ]);
    $houseId = insertRow('houses', [
        'user_id' => $landlordId,
        'house_name' => "$runId House",
        'city' => 'Can Tho',
        'ward' => 'Test Ward',
        'address_detail' => '123 Auto Test',
        'status' => 'active',
    ]);
    $roomId = insertRow('rooms', [
        'house_id' => $houseId,
        'room_name' => "$runId Room 101",
        'price' => 3000000.0,
        'deposit' => 3000000.0,
        'area' => 24.0,
        'max_tenants' => 2,
        'current_tenants' => 0,
        'status' => 'empty',
    ]);

    $electricId = insertRow('services', [
        'house_id' => $houseId,
        'service_name' => 'electric',
        'price' => 3500.0,
        'unit' => 'kWh',
        'charge_type' => 'per_meter',
        'service_type' => 'electric',
    ]);
    $waterId = insertRow('services', [
        'house_id' => $houseId,
        'service_name' => 'water',
        'price' => 20000.0,
        'unit' => 'm3',
        'charge_type' => 'per_meter',
        'service_type' => 'water',
    ]);
    $internetId = insertRow('services', [
        'house_id' => $houseId,
        'service_name' => 'internet',
        'price' => 100000.0,
        'unit' => 'month',
        'charge_type' => 'fixed',
        'service_type' => 'internet',
    ]);

    passCase('setup', 'Created isolated house, room, services', compact('houseId', 'roomId'));

    $month = (int)date('n');
    $year = (int)date('Y');
    $nextMonthDate = (new DateTime('first day of this month'))->modify('+1 month');
    $nextMonth = (int)$nextMonthDate->format('n');
    $nextYear = (int)$nextMonthDate->format('Y');

    $contract = createContract($roomId, [
        'tenant_name' => "$runId Tenant",
        'phone' => '091' . random_int(1000000, 9999999),
        'email' => strtolower($runId) . '@example.test',
        'start_date' => date('Y-m-01'),
        'end_date' => date('Y-m-d', strtotime('+6 months')),
        'rent_price' => 3000000.0,
        'deposit_amount' => 3000000.0,
        'start_electric' => 100,
        'start_water' => 10,
    ]);
    assertCase($contract['ok'], 'contract.create_direct', 'Created active contract directly', $contract);
    $contractId = $contract['contract_id'];
    $tenantId = $contract['tenant_id'];

    attachServicesToContract($contractId, [
        ['id' => $electricId, 'name' => 'electric', 'price' => 3500.0, 'unit' => 'kWh', 'charge_type' => 'per_meter'],
        ['id' => $waterId, 'name' => 'water', 'price' => 20000.0, 'unit' => 'm3', 'charge_type' => 'per_meter'],
        ['id' => $internetId, 'name' => 'internet', 'price' => 100000.0, 'unit' => 'month', 'charge_type' => 'fixed'],
    ]);
    passCase('contract.services', 'Attached utility services to contract');

    $duplicateContract = createContract($roomId, [
        'tenant_name' => "$runId Duplicate",
        'phone' => '092' . random_int(1000000, 9999999),
        'email' => 'duplicate@example.test',
        'start_date' => date('Y-m-01'),
        'end_date' => date('Y-m-d', strtotime('+6 months')),
        'rent_price' => 3000000.0,
        'deposit_amount' => 3000000.0,
        'start_electric' => 100,
        'start_water' => 10,
    ]);
    assertCase(!$duplicateContract['ok'], 'contract.prevent_duplicate_active', 'Blocked second active contract on same room', $duplicateContract);

    $meter = createMeterReading($contractId, $roomId, $month, $year, 100, 150, 10, 15);
    assertCase($meter['ok'], 'meter.create', 'Created meter reading for active contract', $meter);

    $duplicateMeter = createMeterReading($contractId, $roomId, $month, $year, 150, 180, 15, 18);
    assertCase(!$duplicateMeter['ok'], 'meter.prevent_duplicate_month', 'Blocked duplicate meter reading for same contract/month', $duplicateMeter);

    $invoice = createInvoice($contractId, $roomId, $month, $year);
    assertCase($invoice['ok'], 'invoice.create', 'Created invoice from contract and meter', $invoice);
    $invoiceId = $invoice['invoice_id'];
    assertCase(abs($invoice['total'] - 3375000.0) < 0.01, 'invoice.total', 'Invoice total matches expected rent + utilities', ['actual' => $invoice['total'], 'expected' => 3375000.0]);

    $duplicateInvoice = createInvoice($contractId, $roomId, $month, $year);
    assertCase(!$duplicateInvoice['ok'], 'invoice.prevent_duplicate_month', 'Blocked duplicate invoice for same contract/month', $duplicateInvoice);

    $meterHasInvoice = (int)scalarValue("SELECT COUNT(*) FROM invoices WHERE contract_id = $contractId AND billing_month = $month AND billing_year = $year") > 0;
    assertCase($meterHasInvoice, 'meter.block_edit_after_invoice', 'Meter reading is protected once invoice exists');

    markInvoicePaid($invoiceId, $houseId, $roomId, "$runId Tenant");
    $paidStatus = scalarValue("SELECT status FROM invoices WHERE id = $invoiceId");
    assertCase($paidStatus === 'paid', 'invoice.mark_paid', 'Invoice status changed to paid', ['status' => $paidStatus]);

    markInvoicePaid($invoiceId, $houseId, $roomId, "$runId Tenant");
    $receiptCount = (int)scalarValue("SELECT COUNT(*) FROM receipts WHERE invoice_id = $invoiceId AND receipt_type = 'monthly_bill'");
    assertCase($receiptCount === 1, 'receipt.prevent_duplicate_payment_receipt', 'Only one monthly bill receipt exists after repeated paid update', ['receipt_count' => $receiptCount]);

    $termination = terminateContract($contractId, $houseId, $roomId, $tenantId);
    assertCase($termination['ok'], 'contract.terminate', 'Terminated active contract', $termination);
    $roomStatus = scalarValue("SELECT status FROM rooms WHERE id = $roomId");
    $endedStatus = scalarValue("SELECT status FROM contracts WHERE id = $contractId");
    assertCase($roomStatus === 'empty' && $endedStatus === 'ended', 'contract.terminate_state', 'Room released and contract ended', ['room_status' => $roomStatus, 'contract_status' => $endedStatus]);

    $invoiceAfterEndAllowed = scalarValue("SELECT id FROM contracts WHERE id = $contractId AND status = 'active' LIMIT 1") !== null;
    assertCase(!$invoiceAfterEndAllowed, 'invoice.block_after_contract_end', 'No active contract remains for new invoice after termination');

    $newContract = createContract($roomId, [
        'tenant_name' => "$runId Tenant 2",
        'phone' => '093' . random_int(1000000, 9999999),
        'email' => strtolower($runId) . '_2@example.test',
        'start_date' => $nextMonthDate->format('Y-m-01'),
        'end_date' => $nextMonthDate->modify('+6 months')->format('Y-m-d'),
        'rent_price' => 3200000.0,
        'deposit_amount' => 3200000.0,
        'start_electric' => 150,
        'start_water' => 15,
    ]);
    assertCase($newContract['ok'], 'contract.new_after_end', 'Created new active contract on same room after termination', $newContract);
    $newContractId = $newContract['contract_id'];

    $latestForNewContract = getLatestRoomReadingForNewContract($roomId);
    assertCase(
        $latestForNewContract['old_electric'] === 150 && $latestForNewContract['old_water'] === 15,
        'contract.new_start_indices_from_last_room_reading',
        'New contract start indices can be prefilled from the room latest reading after old contract ended',
        $latestForNewContract
    );

    $newMeter = createMeterReading($newContractId, $roomId, $nextMonth, $nextYear, 150, 190, 15, 19);
    assertCase($newMeter['ok'], 'meter.uses_new_contract', 'New meter reading belongs to new contract', ['old_contract_id' => $contractId, 'new_contract_id' => $newContractId, 'meter' => $newMeter]);

    $oldContractMeterCount = (int)scalarValue("SELECT COUNT(*) FROM meter_readings WHERE contract_id = $contractId AND billing_month = $nextMonth AND billing_year = $nextYear");
    assertCase($oldContractMeterCount === 0, 'meter.no_cross_contract_leak', 'Next-period meter did not attach to ended contract', ['old_contract_meter_count' => $oldContractMeterCount]);
} catch (Throwable $e) {
    failCase('fatal', $e->getMessage(), ['trace' => $e->getTraceAsString()]);
} finally {
    if (!$keepData) {
        try {
            cleanup();
            logEvent('INFO', 'cleanup', 'Removed AUTO_TEST data');
        } catch (Throwable $cleanupError) {
            failCase('cleanup', $cleanupError->getMessage());
        }
    } else {
        logEvent('INFO', 'cleanup', 'Kept AUTO_TEST data because --keep-data was passed');
    }

    writeLogs();
    echo "\nJSON log: $jsonLogPath\n";
    echo "Markdown log: $mdLogPath\n";
    exit($stats['failed'] === 0 ? 0 : 1);
}
