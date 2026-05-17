<?php
declare(strict_types=1);

$startedAt = date('Ymd_His');
$runId = 'AUTO_ALL_' . $startedAt . '_' . random_int(1000, 9999);
$root = dirname(__DIR__, 2);
$logDir = __DIR__ . '/logs';
if (!is_dir($logDir)) mkdir($logDir, 0777, true);

$skipApi = in_array('--skip-api', $argv ?? [], true);
$baseUrl = 'http://localhost/ql_tro/backend_api';
$keepData = in_array('--keep-data', $argv ?? [], true);

foreach ($argv ?? [] as $arg) {
    if (str_starts_with($arg, '--base-url=')) {
        $baseUrl = rtrim(substr($arg, strlen('--base-url=')), '/');
    }
}

$suites = [
    [
        'name' => 'contract_invoice_flow',
        'script' => __DIR__ . '/contract_invoice_flow_test.php',
        'args' => [],
    ],
    [
        'name' => 'tenant_account_linking_flow',
        'script' => __DIR__ . '/tenant_account_linking_flow_test.php',
        'args' => [],
    ],
];

if (!$skipApi) {
    $suites[] = [
        'name' => 'tenant_account_linking_api',
        'script' => __DIR__ . '/tenant_account_linking_api_test.php',
        'args' => ['--base-url=' . $baseUrl],
    ];
}

if ($keepData) {
    foreach ($suites as &$suite) {
        $suite['args'][] = '--keep-data';
    }
    unset($suite);
}

function commandString(array $parts): string
{
    $isWindows = strtoupper(substr(PHP_OS, 0, 3)) === 'WIN';
    return implode(' ', array_map(function ($part) use ($isWindows) {
        $part = (string)$part;
        if ($isWindows && preg_match('/^[A-Za-z0-9_\\-\\.\\:\\/\\\\=]+$/', $part)) {
            return $part;
        }
        return escapeshellarg($part);
    }, $parts));
}

function runCommand(array $parts, ?string $cwd = null): array
{
    $cmd = commandString($parts);
    $oldCwd = getcwd();
    if ($cwd) chdir($cwd);

    $output = [];
    $exitCode = 0;
    exec($cmd . ' 2>&1', $output, $exitCode);

    if ($cwd && $oldCwd !== false) chdir($oldCwd);

    return [
        'command' => $cmd,
        'cwd' => $cwd,
        'exit_code' => $exitCode,
        'output' => implode(PHP_EOL, $output),
    ];
}

$events = [];

foreach ($suites as $suite) {
    $lint = runCommand(['php', '-l', $suite['script']], $root);
    $events[] = [
        'suite' => $suite['name'],
        'step' => 'lint',
        'status' => $lint['exit_code'] === 0 ? 'PASS' : 'FAIL',
        'context' => $lint,
    ];

    if ($lint['exit_code'] !== 0) {
        continue;
    }

    $cmd = array_merge(['php', $suite['script']], $suite['args']);
    $run = runCommand($cmd, $root);
    $events[] = [
        'suite' => $suite['name'],
        'step' => 'run',
        'status' => $run['exit_code'] === 0 ? 'PASS' : 'FAIL',
        'context' => $run,
    ];
}

$passed = count(array_filter($events, fn($event) => $event['status'] === 'PASS'));
$failed = count(array_filter($events, fn($event) => $event['status'] === 'FAIL'));

$summary = [
    'run_id' => $runId,
    'created_at' => date('c'),
    'base_url' => $baseUrl,
    'skip_api' => $skipApi,
    'keep_data' => $keepData,
    'stats' => [
        'passed' => $passed,
        'failed' => $failed,
    ],
    'events' => $events,
];

$jsonLogPath = $logDir . "/all_tests_$runId.json";
$mdLogPath = $logDir . "/all_tests_$runId.md";
file_put_contents($jsonLogPath, json_encode($summary, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

$md = "# Auto test summary\n\n";
$md .= "- Run ID: `$runId`\n";
$md .= "- Base URL: `$baseUrl`\n";
$md .= "- Skip API: " . ($skipApi ? 'yes' : 'no') . "\n";
$md .= "- Keep data: " . ($keepData ? 'yes' : 'no') . "\n";
$md .= "- Passed: $passed\n";
$md .= "- Failed: $failed\n\n";
$md .= "| Status | Suite | Step |\n|---|---|---|\n";
foreach ($events as $event) {
    $md .= "| {$event['status']} | {$event['suite']} | {$event['step']} |\n";
}
file_put_contents($mdLogPath, $md);

foreach ($events as $event) {
    echo "[{$event['status']}] {$event['suite']} {$event['step']}\n";
}
echo "\nJSON log: $jsonLogPath\n";
echo "Markdown log: $mdLogPath\n";

exit($failed > 0 ? 1 : 0);
