download_backup() {
    log_info "Downloading Gerrit backup file from S3..."
    aws s3 cp "s3://${S3_BUCKET}/${BACKUP_FILE}" .
}

extract_backup() {
    log_info "Extracting Gerrit backup..."
    mkdir -p var/gerrit
    tar xzf "$(basename ${BACKUP_FILE})" -C "var/gerrit"
    chown -R ec2-user:ec2-user var
}

configure_service() {
    log_info "Setting up Gerrit..."

    log_info "Fetching Gerrit version from gerrit-start script..."
    export SERVICE_VERSION=$(curl -s https://raw.githubusercontent.com/couchbase/build-infra/master/terraform/gerrit/files/scripts/gerrit-start | grep "GERRIT_VERSION=" | cut -d'=' -f2)

    if [ -z "${SERVICE_VERSION}" ]; then
        fail_with_status "Failed to fetch Gerrit version from gerrit-start script"
    fi

    log_info "Using Gerrit version: ${SERVICE_VERSION}"

    SERVICE_IMAGE="couchbasebuild/gerrit:${SERVICE_VERSION}"
    SERVICE_PORT="8080"
    SERVICE_CONTAINER_NAME="gerrit_restored"
    HEALTH_CHECK_CMD='["CMD-SHELL", "curl -s -o /dev/null -w '\''%{http_code}'\'' http://localhost:8080 | grep -E '\''200|403'\''"]'
    VOLUME_MOUNTS="      - ./var/gerrit/static:/var/gerrit/static
      - ./var/gerrit/plugins:/var/gerrit/plugins
      - ./var/gerrit/logs:/var/gerrit/logs
      - ./var/gerrit/lib:/var/gerrit/lib
      - ./var/gerrit/index:/var/gerrit/index
      - ./var/gerrit/hooks:/var/gerrit/hooks
      - ./var/gerrit/git:/var/gerrit/git
      - ./var/gerrit/etc:/var/gerrit/etc
      - ./var/gerrit/db:/var/gerrit/db
      - ./var/gerrit/data:/var/gerrit/data
      - ./var/gerrit/cache:/var/gerrit/cache"
    ENVIRONMENT_VARS=""
}

service_main() {
    download_backup
    extract_backup
    configure_service

    mkdir -p screenshot output
    create_screenshot_script
    create_screenshot_dockerfile
    create_docker_compose

    log_info "Starting Gerrit..."
    docker compose up -d gerrit_restored
    docker compose build screenshot
    wait_for_service_health

    log_info "Capturing UI screenshot..."
    docker compose up screenshot

    succeed_with_status "Gerrit service restored and validated successfully"

    log_info "Tidying up"
    docker compose down
}