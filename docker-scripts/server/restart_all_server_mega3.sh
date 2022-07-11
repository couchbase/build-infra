#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Slaves for server.jenkins running on mega3

# Vulcan docker container for SuSE 11
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/server-suse11-build:20180713 vulcan-suse11 5229 server.jenkins.couchbase.com

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
    couchbasebuild/docker-slave:20220510 \
    docker-slave-server \
    2995 server.jenkins.couchbase.com

wait
echo "All done!"
