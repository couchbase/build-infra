#!/bin/bash -ex

# =============================================================================
# Couchbase ${SERVICE_TYPE^} Restore Testing Script
# Generated for service: ${SERVICE}
# =============================================================================

readonly WORKDIR=${WORKDIR}
readonly MAX_RETRIES=${MAX_RETRIES}
readonly RETRY_INTERVAL=${RETRY_INTERVAL}
readonly PLAYWRIGHT_VERSION=${PLAYWRIGHT_VERSION}

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*"
}

fail_with_status() {
    local message="$1"
    log_error "$message"
    echo "FAILURE" > "${WORKDIR}/${STATUS_FILE}"
    exit 1
}

succeed_with_status() {
    local message="$1"
    log_info "$message"
    echo "SUCCESS" > "${WORKDIR}/${STATUS_FILE}"
}

# SERVICE_SPECIFIC_FUNCTIONS_PLACEHOLDER

create_screenshot_script() {
    log_info "Creating screenshot capture script for ${SERVICE_TYPE}"
    cat << SCRIPT > screenshot/capture-ui.js
const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto('http://${SERVICE_CONTAINER_NAME}:${SERVICE_PORT}', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(30000);
    await page.screenshot({ path: '/output/${SCREENSHOT_FILE}'});
    await browser.close();
})().catch(e => console.error(e));
SCRIPT
}

create_screenshot_dockerfile() {
    log_info "Creating screenshot capture Dockerfile"
    cat << DOCKERFILE > screenshot/Dockerfile
FROM mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble
WORKDIR /app
RUN npm install playwright@v${PLAYWRIGHT_VERSION}
COPY capture-ui.js /app/capture-ui.js
CMD ["node", "capture-ui.js"]
DOCKERFILE
}

create_docker_compose() {
    log_info "Creating compose file"
    cat << COMPOSE > docker-compose.yml
services:
  ${SERVICE_CONTAINER_NAME}:
    image: ${SERVICE_IMAGE}
    container_name: ${SERVICE_CONTAINER_NAME}
    volumes:
${VOLUME_MOUNTS}
${ENVIRONMENT_VARS}
    networks:
      - internal
    healthcheck:
      test: ${HEALTH_CHECK_CMD}
      interval: 30s
      timeout: 10s
      retries: 10

  screenshot:
    build: ./screenshot
    container_name: ${SERVICE_TYPE}_screenshot
    volumes:
      - ./output:/output
    networks:
      - internal
    command: node capture-ui.js
    depends_on:
      ${SERVICE_CONTAINER_NAME}:
        condition: service_healthy

networks:
  internal:
    driver: bridge
    internal: true
COMPOSE
}

wait_for_service_health() {
    log_info "Waiting for ${SERVICE_TYPE} to come up..."
    timeout=$((MAX_RETRIES * RETRY_INTERVAL))
    elapsed=0
    interval=5

    while [ $elapsed -lt $timeout ]; do
        health_status=$(docker inspect --format='{{json .State.Health.Status}}' ${SERVICE_CONTAINER_NAME})
        if [ "${health_status}" = '"healthy"' ]; then
            log_info "${SERVICE_TYPE} is healthy"
            return 0
        fi
        sleep $interval
        elapsed=$((elapsed + interval))
    done

    fail_with_status "${SERVICE_TYPE} did not become healthy within ${timeout} seconds"
}

main() {
    mkdir -p ${WORKDIR}
    cd ${WORKDIR}

    log_info "Installing dependencies"
    yum install -y docker jq
    service docker start
    usermod -a -G docker ec2-user

    log_info "Installing docker-compose"
    PLUGIN_DIR=/usr/libexec/docker/cli-plugins
    mkdir -p ${PLUGIN_DIR}
    curl -SL https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-aarch64 -o ${PLUGIN_DIR}/docker-compose
    chmod a+x ${PLUGIN_DIR}/docker-compose

    service_main

    log_info "Uploading validation results to S3"
    aws s3 cp ${WORKDIR}/${STATUS_FILE} "s3://${S3_BUCKET}/restore_testing/${SERVICE}/${STATUS_FILE}"
    aws s3 cp ${WORKDIR}/output/${SCREENSHOT_FILE} "s3://${S3_BUCKET}/restore_testing/${SERVICE}/${SCREENSHOT_FILE}"
}

main "$@"