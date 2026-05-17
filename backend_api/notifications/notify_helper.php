<?php
// backend_api/notifications/notify_helper.php

function createNotification($conn, $user_id, $title, $description, $type, $metadata = null) {
    $metadata_json = $metadata ? json_encode($metadata) : null;
    
    // Đảm bảo bảng có cột metadata
    try {
        $check = $conn->query("SHOW COLUMNS FROM notifications LIKE 'metadata'");
        if ($check && $check->num_rows == 0) {
            $conn->query("ALTER TABLE notifications ADD COLUMN metadata TEXT NULL");
        }
    } catch (Exception $e) {}

    $sql = "INSERT INTO notifications (user_id, title, description, type, metadata, is_read, created_at) 
            VALUES (?, ?, ?, ?, ?, 0, NOW())";
    
    $stmt = $conn->prepare($sql);
    if ($stmt) {
        $stmt->bind_param("issss", $user_id, $title, $description, $type, $metadata_json);
        $stmt->execute();
        $stmt->close();
        return true;
    }
    return false;
}
?>
