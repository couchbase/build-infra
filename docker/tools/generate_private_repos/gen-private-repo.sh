#!/bin/bash
# Wrapper script to generate private repos from release manifest

WORK_DIR=/home/couchbase
cd ${WORK_DIR}/manifest
sudo git pull

sudo cp /etc/credentials.json ${WORK_DIR}/build-tools/generate_private_repos/
sudo cp /etc/settings.yaml ${WORK_DIR}/build-tools/generate_private_repos/

cd ${WORK_DIR}/build-tools/generate_private_repos
sudo ./gen-private-repos.py --input ${WORK_DIR}/manifest/${MANIFEST} --release ${RELEASE} --conf  ${WORK_DIR}/build-tools/generate_private_repos/projects.ini --folder-id ${GOOGLE_FOLDER_ID} || exit 1
