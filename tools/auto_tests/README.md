# Auto Test Tools

## Run all tests

Run every current backend/API regression suite:

```powershell
php tools\auto_tests\run_all_tests.php
```

Options:

```powershell
php tools\auto_tests\run_all_tests.php --skip-api
php tools\auto_tests\run_all_tests.php --base-url=http://your-host/ql_tro/backend_api
php tools\auto_tests\run_all_tests.php --keep-data
```

The runner lints every test script, runs each suite, aggregates the result, and
writes a summary log to:

```text
tools/auto_tests/logs/all_tests_*.md
tools/auto_tests/logs/all_tests_*.json
```

## Contract and invoice flow

Run:

```powershell
php tools\auto_tests\contract_invoice_flow_test.php
```

The test creates isolated `AUTO_TEST_*` data, checks the contract/invoice
relationships, writes logs, then removes the test data.

Logs are saved in:

```text
tools/auto_tests/logs/
```

Use this when you want to inspect the database rows after a failing run:

```powershell
php tools\auto_tests\contract_invoice_flow_test.php --keep-data
```

When `--keep-data` is used, remove the generated `AUTO_TEST_*` data manually
after debugging.

Covered checks:

- Create contract directly on an empty room.
- Block a second active contract on the same room.
- Create meter reading for the active contract.
- Block duplicate meter reading for the same month.
- Create invoice from rent, electric, water, and fixed service.
- Block duplicate invoice for the same contract/month.
- Protect meter reading after an invoice exists.
- Mark invoice as paid and create exactly one receipt.
- Terminate contract and release the room.
- Block invoice creation after contract termination.
- Create a new contract on the same room after termination.
- Ensure next meter reading attaches to the new contract, not the ended one.

## Tenant registration and account linking flow

Run:

```powershell
php tools\auto_tests\tenant_account_linking_flow_test.php
```

The test creates isolated `AUTO_TEST_TENANT_LINK_*` data, checks tenant
registration/linking behavior, writes logs, then removes the test data.

Use this when you want to inspect the database rows after a failing run:

```powershell
php tools\auto_tests\tenant_account_linking_flow_test.php --keep-data
```

Covered checks:

- Register a new account without an existing tenant.
- Register with an active tenant phone and link `tenants.user_id`.
- Do not link inactive/deleted tenants.
- Block duplicate user phone registration.
- Repair an unassigned user-to-tenant link during login.
- Do not link manager/landlord accounts to tenants with the same phone.
- Tenant only sees their own contracts and invoices.
- Tenant sees manual deposits by phone when deposit `user_id` is empty.
- Tenant sees incidents attached to their tenant record.
- Ended/inactive tenant does not keep active renting status.
- Old tenant does not see the new contract created later in the same room.

## Tenant registration and account linking API flow

Run:

```powershell
php tools\auto_tests\tenant_account_linking_api_test.php
```

This version calls the real HTTP endpoints through Apache/PHP:

- `auth/register.php`
- `auth/login.php`
- `contracts/get_contracts.php`
- `invoice/get_invoices.php`
- `deposits/get_deposits.php`
- `incidents/get_incidents.php`

By default it uses:

```text
http://localhost/ql_tro/backend_api
```

To use another host:

```powershell
php tools\auto_tests\tenant_account_linking_api_test.php --base-url=http://your-host/ql_tro/backend_api
```

Use `--keep-data` to inspect generated rows after a failing run.
