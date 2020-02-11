#!/bin/sh

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Slaves for server.jenkins running on mega3

# Backup for zz-server-lightweight (same port as running on mega2)
${SCRIPTPATH}/../restart_jenkinsdocker.py couchbasebuild/server-ubuntu16-build:20200211 zz-server-lightweight-backup 5322 server.jenkins.couchbase.com

# Centos6 watson builder
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts ceejatec/centos-65-couchbase-build:20170522 watson-centos6-01 5222 server.jenkins.couchbase.com
# Debian7 watson builder
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts ceejatec/debian-7-couchbase-build:20170522 watson-debian7 5224 server.jenkins.couchbase.com
# Centos 7 watson builder
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts ceejatec/centos-70-couchbase-build:20170522 watson-centos7-01 5227 server.jenkins.couchbase.com
# Debian8 watson builder
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts ceejatec/debian-8-couchbase-build:20171106 watson-debian8 5229 server.jenkins.couchbase.com

# Vulcan CentOS 6 builder
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/server-centos6-build:20181218 vulcan-centos6 5225 server.jenkins.couchbase.com

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
    couchbasebuild/docker-slave:20200211 \
    docker-slave-server \
    2995 server.jenkins.couchbase.com

wait
echo "All done!"

