#!/bin/bash -ex

set -e

function show_help {
    echo "Usage: ./backup-jenkins.sh <options>"
    echo "Options:"
    echo "   -d :  Data directory to backup. Typically it is JENKINS_HOME (Required)"
    echo "   -j :  Jobs directory to backup, if different from JENKINS_HOME/jobs (Optional)"
    echo "   -b :  Full backup directory, if needed. This is for full backup only."
    echo "         Full backups are not ftp-ed to NAS. If this option is not given"
    echo "         full backups are not made. (Optional)"
    echo "   -i :  Instance name (eg, server_jenkins, cv_jenkins, mobile_jenkins) (Required)"
    echo "   -x :  Exclude builds/ directories"
}

while getopts :d:j:b:i:xh ARG; do
    case ${ARG} in
        d) JENKINS_DATA="$OPTARG"
           ;;
        j) JENKINS_JOBS="$OPTARG"
           ;;
        b) FULL_BACKUP_DIR="$OPTARG"
           ;;
        i) INSTANCE_NAME="$OPTARG"
           ;;
        x) EXCLUDE_BUILDS="--exclude=jobs/*/builds"
           ;;
        h) show_help
           exit 0
           ;;
        \?) # Unrecognized option; show help
            echo -e \\n"Option -${OPTARG} not allowed."
            show_help
            exit 1
    esac
done

if [[ -z "$JENKINS_DATA" ]]; then
    echo "Data directory (-d) is required"
    exit 1
fi

if [[ -z "$INSTANCE_NAME" ]]; then
    echo "Instance name (-i) is required"
    exit 1
fi

if [[ -n "$JENKINS_DATA" && ! -d "$JENKINS_DATA" ]]; then
    echo "Data directory ${JENKINS_DATA} doesn't exist"
    exit 1
fi

if [[ -n "$JENKINS_JOBS" && ! -d "$JENKINS_JOBS" ]]; then
    echo "Jobs directory ${JENKINS_JOBS} doesn't exist"
    exit 1
fi

if [[ -n "$FULL_BACKUP_DIR" && ! -d "$FULL_BACKUP_DIR" ]]; then
    echo "Full backup directory ${FULL_BACKUP_DIR} doesn't exist"
    exit 1
fi

# Remove any old temporary backup tarball dumps
/bin/rm -f jenkins_backup*tar.gz

DAYOFWEEK=$(/bin/date +%a)
DUMP=jenkins_backup.${DAYOFWEEK}.tar.gz

# Temporarily turn off error mode as tar will nearly always return
# a non-zero failure since the Jenkins must remain live during the
# backup (since it's the one running this script)
set +e
SCRIPT_DIR=$(dirname $0)
echo "Starting minimal backup at $(/bin/date)"
nice -n 19 tar \
    --exclude-from ${SCRIPT_DIR}/jenkins_backup_exclusions ${EXCLUDE_BUILDS} \
    -zcf ${DUMP} ${JENKINS_DATA} ${JENKINS_JOBS}
echo "Return code was $?"
echo "File size is $(du -sk ${DUMP} | awk '{print $1}')K"
echo "Minimal backup finished at $(/bin/date)"
set -e

if [[ "$DAYOFWEEK" == "Sun" && -n "$FULL_BACKUP_DIR" ]]; then
   echo "Starting full backup at $(/bin/date)"
   nice -n 19 rsync -au ${JENKINS_DATA} ${JENKINS_JOBS} ${FULL_BACKUP_DIR}
   echo "Full backup finished at $(/bin/date)"
fi
