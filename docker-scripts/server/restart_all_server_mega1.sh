#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Slaves for server.jenkins running on mega1

# Vulcan docker container for SuSE 11
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/server-suse11-build:20180713 vulcan-suse11 5229 server.jenkins.couchbase.com

wait
echo "All done!"
