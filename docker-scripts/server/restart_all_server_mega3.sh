#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Slaves for server.jenkins running on mega3

# Backup for zz-server-lightweight (same port as running on mega2)
${SCRIPTPATH}/../restart_jenkinsdocker.py couchbasebuild/zz-lightweight:20210208 zz-server-lightweight-backup 5322 server.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py couchbasebuild/zz-lightweight:20210225 zz-server-lightweight-ubuntu20-backup 5324 server.jenkins.couchbase.com

# server.jenkins slave for running Ansible playbooks
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/ansible-slave:20180312 ansible-slave-server 2999 server.jenkins.couchbase.com

# This recreates server.jenkins' "docker-slave-server", a slave
# which exists only to launch one-off Docker commands. Some of
# those commands require certain directories to be mounted.
${SCRIPTPATH}/../restart_jenkinsdocker.py \
    --mount-dir /home/couchbase/check_missing_commits:/home/couchbase/check_missing_commits \
        /home/couchbase/check_builds:/home/couchbase/check_builds \
        /home/couchbase/repo_upload:/home/couchbase/repo_upload \
    --mount-docker \
    couchbasebuild/docker-slave:20201019 \
    docker-slave-server \
    2995 server.jenkins.couchbase.com

wait
echo "All done!"
