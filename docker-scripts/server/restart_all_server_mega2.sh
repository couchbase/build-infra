#!/bin/sh

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Slaves for server.jenkins running on mega2

# Vulcan Ubuntu 14.04 builder
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/server-ubuntu14-build:20180829 vulcan-ubuntu14.04 5232 server.jenkins.couchbase.com
# Spock Ubuntu 16.04 builder - using CV image because that helps some
# cbdeps builds, notably jemalloc needing valgrind headers
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts ceejatec/ubuntu-1604-couchbase-cv:20170522 spock-ubuntu16.04 5238 server.jenkins.couchbase.com
# Spock Debian 9.1 builder
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts ceejatec/debian-9-couchbase-build:20170911 spock-debian9 5230 server.jenkins.couchbase.com
# Primary zz-server-lightweight running on mega2 (same port as backup on mega3)
${SCRIPTPATH}/../restart_jenkinsdocker.py couchbasebuild/zz-lightweight:20220118 zz-server-lightweight 5322 server.jenkins.couchbase.com

# Sonar Scanner slave
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/centos-73-sonar-scanner-build:latest sonarscanner-centos73-01 5240 server.jenkins.couchbase.com

wait
echo "All done!"
