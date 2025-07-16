download_backup() {
    log_info "Downloading Jenkins backup file from S3..."
    aws s3 cp "s3://${S3_BUCKET}/${SERVICE}/${BACKUP_FILE}" .
}

extract_backup() {
    log_info "Extracting Jenkins backup..."
    tar xzf "$(basename ${BACKUP_FILE})" -C "."
    chown -R ec2-user:ec2-user var
}

configure_service() {
    log_info "Setting up Jenkins..."

    export SERVICE_VERSION=$(cat var/jenkins_home/updates/default.json | jq -r ".plugins.credentials.requiredCore")
    log_info "Using Jenkins version: ${SERVICE_VERSION}"

    log_info "Disabling Okta..."
    sed -i.bak 's|<useSecurity>true</useSecurity>|<useSecurity>false</useSecurity>|' "var/jenkins_home/config.xml" && rm "var/jenkins_home/config.xml.bak"
    sed -i.bak -z 's|<securityRealm.*</securityRealm>||g' "var/jenkins_home/config.xml" && rm "var/jenkins_home/config.xml.bak"
    sed -i.bak -z 's|<authorizationStrategy.*<\/authorizationStrategy>||g' "var/jenkins_home/config.xml" && rm "var/jenkins_home/config.xml.bak"

    SERVICE_IMAGE="jenkins/jenkins:${SERVICE_VERSION}"
    SERVICE_PORT="8080"
    SERVICE_CONTAINER_NAME="jenkins_restored"
    HEALTH_CHECK_CMD='["CMD-SHELL", "curl -s -o /dev/null -w '\''%{http_code}'\'' http://localhost:8080 | grep -E '\''200|403'\''"]'
    VOLUME_MOUNTS="      - ./var/jenkins_home:/var/jenkins_home"
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

    log_info "Starting Jenkins..."
    docker compose up -d jenkins_restored
    docker compose build screenshot
    wait_for_service_health

    log_info "Capturing UI screenshot..."
    docker compose up screenshot

    succeed_with_status "Jenkins service restored and validated successfully"

    log_info "Tidying up"
    docker compose down
}