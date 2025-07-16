#!/usr/bin/env bash

set -e

PLAYWRIGHT_VERSION=1.49.1

if [ "${1}" = "--help" -o "${1}" = "-h" ]; then
    echo "Usage: $0"
    echo ""
    echo "Required environment variables:"
    echo "  SERVICE          - Service to test (server_jenkins/analytics_jenkins/cv_jenkins/mobile_jenkins/sdk_jenkins/gerrit/build-db)"
    echo "  S3_BUCKET        - S3 bucket for backup files"
    echo "  SECURITY_GROUP_ID - Security group ID"
    echo "  SUBNET_ID        - Subnet ID"
    echo "  VPC_ID           - VPC ID"
    echo ""
    echo "Optional environment variables:"
    echo "  SSH_KEY_NAME     - AWS SSH key name"
    exit 1
fi

for var in SERVICE S3_BUCKET SECURITY_GROUP_ID SUBNET_ID VPC_ID; do
    if [ -z "${!var}" ]; then
        missing_message="${missing_message}  ${var}\n"
    fi
done

if [ ! -z "${missing_message}" ]; then
    echo "Required env vars missing:"
    printf "${missing_message}"
    exit 1
fi

# Parse service type and instance
if [[ "${SERVICE}" == *_jenkins ]]; then
    ROLE="_jenkins_test_role"
    SERVICE_TYPE="jenkins"
    JENKINS_INSTANCE="${SERVICE%_jenkins}"
elif [[ "${SERVICE}" == "gerrit" ]]; then
    ROLE="_gerrit_test_role"
    SERVICE_TYPE="gerrit"
elif [[ "${SERVICE}" == "build-db" ]]; then
    ROLE="_build_db_test_role"
    SERVICE_TYPE="build-db"
else
    echo "Unknown service: ${SERVICE}"
    echo "Supported services: server_jenkins, analytics_jenkins, cv_jenkins, mobile_jenkins, sdk_jenkins, gerrit, build-db"
    exit 1
fi

if [ ! -z "${SSH_KEY_NAME}" ]; then
    SSH_KEY_ARG="--key-name ${SSH_KEY_NAME}"
fi

# Validate bucket structure matches service type
echo "Validating S3 bucket structure..."
if [ "${SERVICE_TYPE}" = "jenkins" ]; then
    # For Jenkins, check if the service subdirectory exists
    if ! aws s3 ls "s3://${S3_BUCKET}/${SERVICE}/" &>/dev/null; then
        echo "ERROR: S3 bucket ${S3_BUCKET} does not contain subdirectory ${SERVICE}/"
        echo "Jenkins backups should be stored in: s3://${S3_BUCKET}/${SERVICE}/"
        echo "Are you sure you're using the correct Jenkins backup bucket?"
        exit 1
    fi
    echo "Found Jenkins service directory: s3://${S3_BUCKET}/${SERVICE}/"
elif [ "${SERVICE_TYPE}" = "gerrit" ]; then
    # For Gerrit, check if backup files exist in root (look for backup-YYYYMMDD.tgz pattern)
    if ! aws s3 ls "s3://${S3_BUCKET}/backup-" &>/dev/null; then
        echo "ERROR: S3 bucket ${S3_BUCKET} does not contain Gerrit backup files (backup-YYYYMMDD.tgz)"
        echo "Gerrit backups should be stored directly in: s3://${S3_BUCKET}/"
        echo "Are you sure you're using the correct Gerrit backup bucket?"
        exit 1
    fi
    echo "Found Gerrit backup files in: s3://${S3_BUCKET}/"
elif [ "${SERVICE_TYPE}" = "build-db" ]; then
    # For build-db, check if logs and backups directories exist
    if ! aws s3 ls "s3://${S3_BUCKET}/logs/" &>/dev/null; then
        echo "ERROR: S3 bucket ${S3_BUCKET} does not contain logs/ directory"
        echo "build-db backups should have: s3://${S3_BUCKET}/logs/"
        echo "Are you sure you're using the correct build-db backup bucket?"
        exit 1
    fi
    if ! aws s3 ls "s3://${S3_BUCKET}/backups/" &>/dev/null; then
        echo "ERROR: S3 bucket ${S3_BUCKET} does not contain backups/ directory"
        echo "build-db backups should have: s3://${S3_BUCKET}/backups/"
        echo "Are you sure you're using the correct build-db backup bucket?"
        exit 1
    fi
    echo "Found build-db backup structure in: s3://${S3_BUCKET}/"
fi

if [ "${SERVICE_TYPE}" = "jenkins" ]; then
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        BACKUP_DAY=$(date -v-1d +"%a")
    else
        BACKUP_DAY=$(date -d "yesterday" +"%a")
    fi
    BACKUP_FILE="jenkins_backup.${BACKUP_DAY}.tar.gz"
elif [ "${SERVICE_TYPE}" = "gerrit" ]; then
    if [[ "${OSTYPE}" == "darwin"* ]]; then
        BACKUP_DATE=$(date -v-1d -v-sat +"%Y%m%d")
    else
        BACKUP_DATE=$(date -d "last saturday" +"%Y%m%d")
    fi
    BACKUP_FILE="backup-${BACKUP_DATE}.tgz"
fi

# Set BACKUP_PATH for build-db services
if [ "${SERVICE_TYPE}" = "build-db" ]; then
    # Find the latest backup directory (previous night's backup)
    echo "Finding latest build-db backup directory..."
    BACKUP_PATH=$(aws s3 ls "s3://${S3_BUCKET}/backups/" | grep "PRE" | tail -1 | awk '{print $2}' | sed 's|/$||')
    if [ -z "${BACKUP_PATH}" ]; then
        echo "ERROR: No backup directories found in s3://${S3_BUCKET}/backups/"
        exit 1
    fi
    echo "Using backup directory: ${BACKUP_PATH}"
fi

RUN_ID=$(date +%Y-%m-%d-%H-%M-%S)
WORKDIR=/home/ec2-user/restore-test
WORKSPACE=${WORKSPACE:-$WORKDIR}

MAX_RETRIES=60
RETRY_INTERVAL=60

SCREENSHOT_FILE="${RUN_ID}-${SERVICE}-screenshot.jpg"
STATUS_FILE="${RUN_ID}-${SERVICE}-status.txt"
VALIDATION_PATH="restore_testing/${SERVICE}"

REGION="us-east-2"
if [ "${SERVICE_TYPE}" = "build-db" ]; then
    INSTANCE_TYPE="c6g.4xlarge"
elif [ "${SERVICE_TYPE}" = "gerrit" ]; then
    DISK_SIZE=150
fi

DISK_SIZE=${DISK_SIZE:-50}
INSTANCE_TYPE=${INSTANCE_TYPE:-"c6g.2xlarge"}

export BACKUP_FILE BACKUP_PATH SERVICE SERVICE_TYPE JENKINS_INSTANCE MAX_RETRIES RETRY_INTERVAL PLAYWRIGHT_VERSION RUN_ID S3_BUCKET SCREENSHOT_FILE STATUS_FILE WORKDIR

# Generate service-specific userdata script
TEMP_USERDATA=$(mktemp)

# Split template at placeholder and insert service functions
awk '
    /^# SERVICE_SPECIFIC_FUNCTIONS_PLACEHOLDER$/ {
        while ((getline line < "src/'${SERVICE_TYPE}'.sh") > 0) {
            print line
        }
        close("src/'${SERVICE_TYPE}'.sh")
        next
    }
    { print }
' src/userdata-template.sh > "${TEMP_USERDATA}"

USER_DATA=$(envsubst '$BACKUP_FILE,$BACKUP_PATH,$SERVICE,$SERVICE_TYPE,$JENKINS_INSTANCE,$MAX_RETRIES,$PLAYWRIGHT_VERSION,$RETRY_INTERVAL,$RUN_ID,$S3_BUCKET,$SCREENSHOT_FILE,$STATUS_FILE,$WORKDIR' < "${TEMP_USERDATA}")
rm -f "${TEMP_USERDATA}"

printf "Getting latest AL2023 AMI ID... "
AMI_ID=$(aws ssm get-parameters \
    --region ${REGION} \
    --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64 \
    --query "Parameters[0].Value" \
    --output text)
printf "${AMI_ID}\n"

printf "Launching instance... "
INSTANCE_ID=$(aws ec2 run-instances \
    --count=1 \
    --image-id="${AMI_ID}" \
    --instance-type="${INSTANCE_TYPE}" \
    --iam-instance-profile Name="${ROLE}" \
    --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":'${DISK_SIZE}'}}]' \
    --security-group-ids="${SECURITY_GROUP_ID}" \
    --subnet-id="${SUBNET_ID}" \
    --associate-public-ip-address \
    --user-data="${USER_DATA}" \
    --region="${REGION}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${SERVICE_TYPE}-restore-testing},{Key=Owner,Value=build-team}]" \
    --query "Instances[0].InstanceId" \
    --output text \
    $SSH_KEY_ARG)

if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to launch instance"
    exit 1
fi

trap "echo; echo 'Removing instance ${INSTANCE_ID}'; aws ec2 terminate-instances --instance-ids ${INSTANCE_ID} --region ${REGION}; aws ec2 wait instance-terminated --instance-ids ${INSTANCE_ID} --region ${REGION}" EXIT
printf "${INSTANCE_ID}... "
aws ec2 wait instance-running --instance-ids ${INSTANCE_ID} --region ${REGION}
printf "running\n"

check_complete=false

echo "Waiting for validation to complete..."
for i in $(seq 1 ${MAX_RETRIES}); do
    if aws s3 ls s3://${S3_BUCKET}/${VALIDATION_PATH}/${STATUS_FILE} &>/dev/null; then
        check_complete=true
        break
    fi
    echo "Attempt $i of ${MAX_RETRIES}"
    sleep "${RETRY_INTERVAL}"
done

echo

if [ "$check_complete" = false ]; then
    echo "Validation did not complete within the specified time"
    exit 1
fi

aws s3 cp s3://${S3_BUCKET}/${VALIDATION_PATH}/${STATUS_FILE} ${WORKSPACE}/${STATUS_FILE}
aws s3 rm s3://${S3_BUCKET}/${VALIDATION_PATH}/${STATUS_FILE}

STATUS=$(cat ${WORKSPACE}/${STATUS_FILE})
echo "Status from instance: ${STATUS}"

aws s3 cp s3://${S3_BUCKET}/${VALIDATION_PATH}/${SCREENSHOT_FILE} ${WORKSPACE}/${SCREENSHOT_FILE}
aws s3 rm s3://${S3_BUCKET}/${VALIDATION_PATH}/${SCREENSHOT_FILE}

if [ "${STATUS}" = "SUCCESS" ]; then
    echo "Validation successful"
    exit 0
else
    echo "Validation failed"
    exit 1
fi
