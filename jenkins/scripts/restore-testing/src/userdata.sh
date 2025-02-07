#!/bin/bash -ex

# Various environment variables are exported in go.sh,
# envsubst is used to replace the following variables
# when this script is seeded to the instance:
# - BACKUP_FILE
# - JENKINS
# - JENKINS_HOME
# - MAX_RETRIES
# - RETRY_INTERVAL
# - PLAYWRIGHT_VERSION
# - RUN_ID
# - S3_BUCKET
# - SCREENSHOT_FILE
# - STATUS_FILE
# - WORKDIR

mkdir -p ${WORKDIR}
cd ${WORKDIR}

# These are only used in maths below, need to instantiate them first to
# give envsubst a chance to do its thing
MAX_RETRIES=${MAX_RETRIES}
RETRY_INTERVAL=${RETRY_INTERVAL}

echo "[INFO] Installing deps"
yum install -y docker jq

service docker start
usermod -a -G docker ec2-user

echo "[INFO] Installing docker-compose"
PLUGIN_DIR=/usr/libexec/docker/cli-plugins
mkdir -p ${PLUGIN_DIR}
curl -SL https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-aarch64 -o ${PLUGIN_DIR}/docker-compose
chmod a+x ${PLUGIN_DIR}/docker-compose

# Download the backup file
echo "[INFO] Downloading backup file from S3..."
aws s3 cp "s3://${S3_BUCKET}/${JENKINS}_jenkins/${BACKUP_FILE}" .

# Extract the backup file
echo "[INFO] Extracting backup file..."
tar xzf "$(basename ${BACKUP_FILE})" -C "."
chown -R ec2-user:ec2-user var

# Determine Jenkins version
export JENKINS_VERSION=$(cat ${JENKINS_HOME}/updates/default.json | jq -r ".plugins.credentials.requiredCore")

# Disable Okta
echo "[INFO] Disabling Okta..."
sed -i.bak 's|<useSecurity>true</useSecurity>|<useSecurity>false</useSecurity>|' "${JENKINS_HOME}/config.xml" && rm "${JENKINS_HOME}/config.xml.bak"
sed -i.bak -z 's|<securityRealm.*</securityRealm>||g' "${JENKINS_HOME}/config.xml" && rm "${JENKINS_HOME}/config.xml.bak"
sed -i.bak -z 's|<authorizationStrategy.*<\/authorizationStrategy>||g' "${JENKINS_HOME}/config.xml" && rm "${JENKINS_HOME}/config.xml.bak"

# Create Playwright test
echo "[INFO] Creating playwright test file"
mkdir playwright
cat << 'TEST' > playwright/test-ui.js
const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto('http://jenkins:8080')
    await page.screenshot({ path: '/output/${SCREENSHOT_FILE}'});
    await browser.close();
})().catch(e => console.error(e));
TEST

# Create playwright Dockerfile
echo "[INFO] Creating playwright Dockerfile"
cat << 'PLAYWRIGHT' > playwright/Dockerfile
FROM mcr.microsoft.com/playwright:v${PLAYWRIGHT_VERSION}-noble
WORKDIR /app
RUN npm install playwright@v${PLAYWRIGHT_VERSION}
COPY test-ui.js /app/test-ui.js
CMD ["node", "test-ui.js"]
PLAYWRIGHT

# Create compose file
echo "[INFO] Creating compose file"
cat << 'COMPOSE' > docker-compose.yml
services:
  jenkins:
    image: jenkins/jenkins:${JENKINS_VERSION}
    container_name: jenkins_restored
    volumes:
      - ./var/jenkins_home:/var/jenkins_home
    networks:
      - internal
    healthcheck:
      test: ["CMD-SHELL", "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 | grep -E '200|403'"]
      interval: 30s
      timeout: 10s
      retries: 10

  playwright:
    build: ./playwright
    container_name: jenkins_playwright
    volumes:
      - ./output:/output
    networks:
      - internal
    command: node test-ui.js
    depends_on:
      jenkins:
        condition: service_healthy

networks:
  internal:
    driver: bridge
    internal: true
COMPOSE

# Start Jenkins
echo "[INFO] Starting Jenkins..."
docker compose up -d jenkins

# Build playwright
docker compose build playwright

# Wait for Jenkins to come up - we will either receive a 403 or a 200 response code when it's available
echo "[INFO] Waiting for Jenkins to come up..."
timeout=$((MAX_RETRIES * RETRY_INTERVAL))
elapsed=0
interval=5

while [ $elapsed -lt $timeout ]; do
    health_status=$(docker inspect --format='{{json .State.Health.Status}}' jenkins_restored)
    if [ "${health_status}" = '"healthy"' ]; then
        break
    fi
    sleep $interval
    elapsed=$((elapsed + interval))
done

if [ $elapsed -ge $timeout ]; then
    echo "[ERROR] Jenkins did not become healthy within ${timeout} seconds."
    echo "FAILURE" > ${WORKDIR}/$STATUS_FILE
    exit 1
else
    echo "SUCCESS" > ${WORKDIR}/$STATUS_FILE
fi

# UI validation
echo "[INFO] Running tests in playwright"
docker compose up playwright

# Clean up
echo "[INFO] Tidying up"
docker compose down

# Upload results
echo "[INFO] Uploading validation results to S3"
aws s3 cp ${WORKDIR}/${STATUS_FILE} "s3://${S3_BUCKET}/restore_testing/${JENKINS}/${STATUS_FILE}"
aws s3 cp ${WORKDIR}/output/${SCREENSHOT_FILE} "s3://${S3_BUCKET}/restore_testing/${JENKINS}/${SCREENSHOT_FILE}"
