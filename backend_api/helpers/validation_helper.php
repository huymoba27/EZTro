<?php

function qltro_normalize_phone($phone): string
{
    return preg_replace('/[\s\.\-\(\)]+/', '', trim((string)$phone));
}

function qltro_is_valid_phone($phone): bool
{
    $phone = qltro_normalize_phone($phone);
    return preg_match('/^0[0-9]{9,10}$/', $phone) === 1;
}

function qltro_assert_valid_phone($phone, string $message = "Số điện thoại không hợp lệ. Vui lòng nhập 10-11 chữ số và bắt đầu bằng 0."): string
{
    $phone = qltro_normalize_phone($phone);
    if (!qltro_is_valid_phone($phone)) {
        throw new Exception($message);
    }
    return $phone;
}

function qltro_active_tenant_phone_exists(mysqli $conn, string $phone, int $exclude_tenant_id = 0): bool
{
    $phone = qltro_normalize_phone($phone);
    $sql = "SELECT id FROM tenants WHERE phone = ? AND status = 'active' AND deleted_at IS NULL";
    if ($exclude_tenant_id > 0) {
        $sql .= " AND id != ?";
    }
    $sql .= " LIMIT 1";

    $stmt = $conn->prepare($sql);
    if ($exclude_tenant_id > 0) {
        $stmt->bind_param("si", $phone, $exclude_tenant_id);
    } else {
        $stmt->bind_param("s", $phone);
    }
    $stmt->execute();
    $exists = $stmt->get_result()->num_rows > 0;
    $stmt->close();
    return $exists;
}

function qltro_open_deposit_phone_exists(mysqli $conn, string $phone, int $exclude_deposit_id = 0): bool
{
    $phone = qltro_normalize_phone($phone);
    $sql = "SELECT id FROM deposits WHERE customer_phone = ? AND status IN ('pending', 'waiting_payment')";
    if ($exclude_deposit_id > 0) {
        $sql .= " AND id != ?";
    }
    $sql .= " LIMIT 1";

    $stmt = $conn->prepare($sql);
    if ($exclude_deposit_id > 0) {
        $stmt->bind_param("si", $phone, $exclude_deposit_id);
    } else {
        $stmt->bind_param("s", $phone);
    }
    $stmt->execute();
    $exists = $stmt->get_result()->num_rows > 0;
    $stmt->close();
    return $exists;
}
?>
