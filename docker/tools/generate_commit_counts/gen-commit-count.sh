#!/usr/bin/env bash
# Wrapper script to generate commit counts for gerrit/git users

# Ensure a fresh copy of build-tools repo for every run
WORK_DIR=/home/couchbase
cd ${WORK_DIR}
rm -rf ${WORK_DIR}/build-tools
git clone git://github.com/couchbase/build-tools > /dev/null

# Run generate_private_repos program
python3.6  ${WORK_DIR}/build-tools/generate_commit_counts/gen-commit-counts.py --conf ${WORK_DIR}/build-tools/generate_commit_counts/projects.ini  --gerrit-config /etc/patch_via_gerrit.ini --git-config /etc/git_committer.ini --date-range ${DATE_RANGE} --recipient ${EMAIL_RECIPIENT} || exit 1
