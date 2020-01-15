#!/bin/sh

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# SUSE 12 containers (currently hosted on 172.23.96.156)
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts localonly/suse-12-couchbase-build:20170418 spock-suse12-02 3127 server.jenkins.couchbase.com &
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts localonly/suse-12-couchbase-build:20190427 vulcan-suse12-02 3128 server.jenkins.couchbase.com &

wait
echo "All done!"

