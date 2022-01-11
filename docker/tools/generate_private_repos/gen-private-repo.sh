#!/usr/bin/env bash
# Wrapper script to generate private repos from release manifest

# Ensure an up-to-date (unmodified) manifest checkout is available
WORK_DIR=/home/couchbase
cd ${WORK_DIR}
rm -rf manifest
git clone ssh://git@github.com/couchbase/manifest > /dev/null

# Run generate_private_repos program
[[ "$1" == "default" ]] && {
    exec generate_private_repos --input ${WORK_DIR}/manifest/${MANIFEST} --release ${RELEASE} --conf /etc/projects.ini --folder-id ${GOOGLE_FOLDER_ID} || exit 1
}

exec "$@"
