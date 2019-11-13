#!/bin/sh

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# SUSE 12 containers (currently hosted on 172.23.96.152)
${SCRIPTPATH}/../restart_jenkinsdocker.py localonly/suse-12-couchbase-build:20170418 spock-suse12 3125 server.jenkins.couchbase.com &
${SCRIPTPATH}/../restart_jenkinsdocker.py localonly/suse-12-couchbase-build:20190425 vulcan-suse12 3126 server.jenkins.couchbase.com &

wait
echo "All done!"

