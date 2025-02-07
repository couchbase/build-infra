#!/usr/bin/env bash

set -e

PLAYWRIGHT_VERSION=1.49.1
DISK_SIZE=50

if [ -z "${1}" -o "${@: -1}" = "--help" -o "${@: -1}" = "-h" ]; then
    echo "Usage: $0 [analytics/cv/mobile/sdk/server] [aws_ssh_key_name]"
    exit 1
fi

for var in S3_BUCKET SECURITY_GROUP_ID SUBNET_ID ROLE VPC_ID; do
    if [ -z "${!var}" ]; then
        missing_message="${missing_message}  ${var}\n"
    fi
done

if [ ! -z "${missing_message}" ]; then
    echo "Required env vars missing:"
    printf "${missing_message}"
    exit 1
fi

JENKINS=$1

if [ ! -z "${2}" ]; then
    SSH_KEY_ARG="--key-name ${2}"
fi

if [[ "${OSTYPE}" == "darwin"* ]]; then
    BACKUP_DAY=$(date -v-1d +"%a")
else
    BACKUP_DAY=$(date -d "yesterday" +"%a")
fi

BACKUP_FILE="jenkins_backup.${BACKUP_DAY}.tar.gz"

RUN_ID=$(date +%Y-%m-%d-%H-%M-%S)
WORKDIR=/home/ec2-user/restore-test
WORKSPACE=${WORKSPACE:-$WORKDIR}

MAX_RETRIES=60
RETRY_INTERVAL=60

JENKINS_HOME="var/jenkins_home"
SCREENSHOT_FILE="${RUN_ID}-${JENKINS}-screenshot.jpg"
STATUS_FILE="${RUN_ID}-${JENKINS}-status.txt"
VALIDATION_PATH="restore_testing/${JENKINS}"

REGION="us-east-2"
INSTANCE_TYPE="c6g.2xlarge"

export BACKUP_FILE JENKINS JENKINS_HOME MAX_RETRIES RETRY_INTERVAL PLAYWRIGHT_VERSION RUN_ID S3_BUCKET SCREENSHOT_FILE STATUS_FILE WORKDIR
USER_DATA=$(envsubst '$BACKUP_FILE,$JENKINS,$JENKINS_HOME,$MAX_RETRIES,$PLAYWRIGHT_VERSION,$RETRY_INTERVAL,$RUN_ID,$S3_BUCKET,$SCREENSHOT_FILE,$STATUS_FILE,$WORKDIR' < src/userdata.sh)

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
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-restore-testing},{Key=Owner,Value=build-team}]' \
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

found=false

echo "Waiting for validation to complete..."
for i in $(seq 1 ${MAX_RETRIES}); do
    if aws s3 ls s3://${S3_BUCKET}/${VALIDATION_PATH}/${STATUS_FILE} &>/dev/null; then
        found=true
        break
    fi
    echo "Attempt $i of ${MAX_RETRIES}"
    sleep "${RETRY_INTERVAL}"
done

echo

if [ "$found" = false ]; then
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
