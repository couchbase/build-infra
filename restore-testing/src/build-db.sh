download_backup() {
    log_info "Syncing cbbackupmgr archive structure from S3..."
    mkdir -p archive/backups

    log_info "Syncing backup timestamp directory: ${BACKUP_PATH}..."
    if ! aws s3 sync "s3://${S3_BUCKET}/backups/${BACKUP_PATH}/" "archive/backups/${BACKUP_PATH}/"; then
        fail_with_status "Failed to download backup directory: s3://${S3_BUCKET}/backups/${BACKUP_PATH}/"
    fi

    if [ ! -d "archive/backups/${BACKUP_PATH}" ] || [ -z "$(ls -A "archive/backups/${BACKUP_PATH}" 2>/dev/null)" ]; then
        fail_with_status "Backup directory is missing or empty: archive/backups/${BACKUP_PATH}"
    fi

    log_info "Syncing logs directory..."
    aws s3 sync "s3://${S3_BUCKET}/logs/" "archive/logs/" || log_info "Warning: Failed to sync logs directory"

    log_info "Syncing repository metadata..."
    metadata_downloaded=false

    if aws s3 cp "s3://${S3_BUCKET}/backups/backup-meta.json" "archive/backups/backup-meta.json" 2>/dev/null; then
        log_info "Downloaded backup-meta.json"
        metadata_downloaded=true
    fi

    if aws s3 cp "s3://${S3_BUCKET}/backups/.info" "archive/backups/.info" 2>/dev/null; then
        log_info "Downloaded .info"
        metadata_downloaded=true
    fi

    if aws s3 cp "s3://${S3_BUCKET}/backups/README.md" "archive/backups/README.md" 2>/dev/null; then
        log_info "Downloaded README.md"
        metadata_downloaded=true
    fi

    if [ "$metadata_downloaded" = "false" ]; then
        fail_with_status "Failed to download repository metadata files (backup-meta.json, .info, README.md)"
    fi

    log_info "Syncing archive metadata..."
    if ! aws s3 cp "s3://${S3_BUCKET}/.backup" "archive/.backup" 2>/dev/null; then
        log_info "Warning: .backup file not found - cbbackupmgr may still work without it"
    fi

    log_info "✓ Successfully downloaded cbbackupmgr archive structure"
}

create_couchbase_screenshot_script() {
    log_info "Creating Couchbase-specific screenshot capture script"
    cat << SCRIPT > screenshot/capture-ui.js
const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();

    try {
        // Navigate to Couchbase login page
        await page.goto('http://${SERVICE_CONTAINER_NAME}:${SERVICE_PORT}', { waitUntil: 'domcontentloaded' });

        // Wait for login form to be visible
        await page.waitForSelector('#auth-username-input', { timeout: 30000 });

        // Fill in login credentials
        await page.fill('#auth-username-input', 'Administrator');
        await page.fill('#auth-password-input', 'password');

        // Click sign in button
        await page.click('button[type="submit"]');

        // Wait for the main dashboard to load and then navigate to buckets
        await page.waitForSelector('a[mn-tab="buckets"]', { timeout: 60000 });
        await page.click('a[mn-tab="buckets"]');

        // Wait for buckets page to load
        await page.waitForTimeout(5000);

        // Take screenshot
        await page.screenshot({ path: '/output/${SCREENSHOT_FILE}', fullPage: true });

    } catch (error) {
        console.error('Test failed:', error);
        // Take screenshot even if test fails for debugging
        await page.screenshot({ path: '/output/${SCREENSHOT_FILE}' });
        throw error;
    } finally {
        await browser.close();
    }
})().catch(e => console.error(e));
SCRIPT
}

configure_service() {
    log_info "Setting up Couchbase server..."

    # Extract version from backup restrictions.json which contains the actual server version
    RESTRICTIONS_FILE=$(find archive/backups -name ".restrictions.json" | head -1)
    if [ -f "$RESTRICTIONS_FILE" ]; then
        export SERVICE_VERSION=$(grep -o '"min_version":"[^"]*"' "$RESTRICTIONS_FILE" | cut -d'"' -f4)
        log_info "Using Couchbase version from backup restrictions: ${SERVICE_VERSION}"
    elif [ -f "archive/backups/README.md" ]; then
        export SERVICE_VERSION=$(grep "Version:" archive/backups/README.md | sed 's/Version: cbbackupmgr-//' | cut -d'-' -f1)
        log_info "Using Couchbase version from backup README: ${SERVICE_VERSION}"
    else
        export SERVICE_VERSION="7.6.6"
        log_info "No version info found, using fallback Couchbase version: ${SERVICE_VERSION}"
    fi

    SERVICE_IMAGE="couchbase:${SERVICE_VERSION}"
    SERVICE_PORT="8091"
    SERVICE_CONTAINER_NAME="couchbase_restored"
    HEALTH_CHECK_CMD='["CMD-SHELL", "curl -s -o /dev/null -w '\''%{http_code}'\'' http://localhost:8091 | grep -E '\''200|301|403'\''"]'
    VOLUME_MOUNTS="      - ./archive:/archive"
    ENVIRONMENT_VARS=""
}

validate_restoration() {
    log_info "Couchbase container is healthy, starting backup restoration..."

    log_info "Initializing Couchbase cluster..."
    docker exec ${SERVICE_CONTAINER_NAME} couchbase-cli cluster-init \
        --cluster localhost:8091 \
        --cluster-username Administrator \
        --cluster-password password \
        --cluster-ramsize 16384 \
        --services data,index,query,fts

    sleep 10

    log_info "Restoring backup using cbbackupmgr from archive (synthetic full)..."
    restore_output=$(docker exec ${SERVICE_CONTAINER_NAME} cbbackupmgr restore \
        --archive /archive \
        --repo backups \
        --auto-create-buckets \
        --cluster localhost:8091 \
        --username Administrator \
        --password password 2>&1)

    restore_exit_code=$?
    echo "$restore_output"

    if [ $restore_exit_code -eq 0 ] && echo "$restore_output" | grep -q "Restore completed successfully"; then
        log_info "✓ cbbackupmgr reports restore completed successfully"

        # Extract statistics from cbbackupmgr output (format: "Copied all data in 23.965s (Avg. 39.67MiB/Sec)         1046503 items / 912.43MiB")
        stats_line=$(echo "$restore_output" | grep "Copied all data" | head -1)
        total_items=$(echo "$stats_line" | grep -o '[0-9][0-9,]* items' | sed 's/,//g' | awk '{print $1}')
        total_size=$(echo "$stats_line" | grep -o '/ [0-9][0-9.]*[A-Z]*iB' | sed 's|^/ ||')

        log_info "Restore statistics from cbbackupmgr:"
        log_info "  Total items restored: ${total_items:-0}"
        log_info "  Total data restored: ${total_size:-0}"

        bucket_count=$(echo "$restore_output" | grep -c "| Succeeded |")
        log_info "  Buckets restored: ${bucket_count}"

        error_count=$(echo "$restore_output" | grep "Errored" | awk '{sum += $4} END {print sum+0}')

        if [ "$error_count" -gt 0 ]; then
            fail_with_status "${error_count} errors occurred during restore"
        elif [ -n "$total_items" ] && [ "$total_items" -gt 0 ]; then
            succeed_with_status "✓ Restoration validation successful: ${total_items} items restored"
        else
            fail_with_status "✗ No items were restored according to cbbackupmgr output"
        fi

    else
        log_error "✗ cbbackupmgr restore failed or did not complete successfully"
        log_error "Exit code: $restore_exit_code"
        fail_with_status "cbbackupmgr restore failed"
    fi
}

service_main() {
    download_backup
    configure_service

    mkdir -p screenshot output
    create_couchbase_screenshot_script
    create_screenshot_dockerfile
    create_docker_compose

    log_info "Starting Couchbase..."
    docker compose up -d couchbase_restored
    docker compose build screenshot
    wait_for_service_health

    validate_restoration

    log_info "Capturing UI screenshot..."
    docker compose up screenshot

    log_info "Tidying up"
    docker compose down
}