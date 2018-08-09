#!/bin/bash
# Wrapper script to run the backup
# Required mount point: nas-n.mgt.couchbase.com:/data/builds /builds
# Required VMs' UUID, BACKUP_NAME (name appended to .xva file for details
# description), and CLUSTER (XEN)

BACKUP_DIR="/builds/backups/xen/${CLUSTER}"

if [ ! -d /builds/backups/xen/ ]; then
    echo "Required backup directory does not exist: /builds/backups/xen/"
    exit 1
else
    mkdir ${BACKUP_DIR}
fi

# Ensure  S3_BUCKET_NAME bucket exist
source /home/couchbase/.ssh/aws-credentials.sh
s3cmd ls s3://${S3_BUCKET_NAME}/ || exit 1

# Convert YAML to JSON Xen credentials
# Required the same mount point of update_build_system_inventory's credential YAML file
python3 ./xen-credential-yaml-to-json.py --repository ${BACKUP_DIR} --file /etc/servers.yaml --json-output /tmp/xenbackup.json || exit 1

# Run Backup
NAME_OPTION=''
if [ ! -z "${BACKUP_NAME}" ]; then
    NAME_OPTION="--backup-name ${BACKUP_NAME}"
fi
python /xenbackup/xenbackup backup ${UUID} --cluster ${CLUSTER} --config-file /tmp/xenbackup.json ${NAME_OPTION} || exit 1


# Publish .xva files to S3's xen-cluster bucket
source /home/couchbase/.ssh/aws-credentials.sh
s3cmd put /builds/backups/xen/${CLUSTER}/${UUID}/*.xva s3://${S3_BUCKET_NAME}/ || exit 1
