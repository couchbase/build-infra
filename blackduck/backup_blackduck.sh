#!/bin/bash -ex

# Script to back up our Black Duck Hub data and configuration. Expected
# to run on the Black Duck Hub server where Black Duck is installed in
# `/home/couchbase/blackduck`, and also expects the `/buildteam`
# mountpoint to be available.

BD_ROOT=/home/couchbase/blackduck
BACKUP_ROOT=/buildteam/backups/blackduck

if [ ! -d ${BD_ROOT} ]; then
    echo "Black Duck Hub not installed at ${BD_ROOT}"
    exit 1
fi

if [ ! -d /buildteam ]; then
    echo "Mountpoint /buildteam not available"
    exit 1
fi

source ${BD_ROOT}/couchbase-blackduck-versions

# Create backup directory
BACKUP_DIR=${BACKUP_ROOT}/blackduck_couchbase_$(date +%Y%m%d%H%M)
mkdir -p ${BACKUP_DIR}

# Create backup
${BD_ROOT}/hub-${HUB_VERSION}/docker-swarm/bin/hub_create_data_dump.sh  \
    --live-system \
    ${BACKUP_DIR}/ 2>&1

# Copy important local config files - needs to be done after the backup
# with newer hub versions, as `hub_create_data_dump.sh` checks to ensure
# the directory is empty before starting.
cp ${BD_ROOT}/couchbase* \
    ${BD_ROOT}/start_hub.sh \
    ${BACKUP_DIR}/

# Retain 60 backups
pushd ${BACKUP_DIR}/..
ls -t | tail -n +60 | xargs rm -rf >> /tmp/backup-blackduck.log

# Sync backup directory to S3, but only if it's definitely mounted from
# the NAS - since we have `--delete` here, we don't want to blow away
# old data from S3 if the NAS isn't mounted and the older backups are
# missing locally.
if [ ! -e ${BACKUP_ROOT}/DONT_DELETE_THIS.txt ]; then
    echo "NAS mountpoint not found, not syncing to S3!"
    exit 1
fi

# And if we ARE here, then update the modification date of the marker
# file so we don't delete it after 60 days above.
touch ${BACKUP_ROOT}/DONT_DELETE_THIS.txt

# Finally, sync up to S3, deleting any files that are no longer present
# on the NAS.
aws s3 sync --delete ${BACKUP_ROOT}/ s3://cb-blackduck.backups/
