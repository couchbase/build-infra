#!/bin/bash -ex

SCRIPT_DIR=$(dirname $(readlink -e -- "${BASH_SOURCE}"))
cd "${SCRIPT_DIR}/.."

rye sync
rye run load_build_database -d -c ~/.ssh/build_db_load_conf.ini
rye run jira_commenter -d -c ~/.ssh/build_db_load_conf.ini \
  --cloud-creds ~/.ssh/cloud-jira-creds.json
