#!/bin/bash

# These are currently all hosted on mega

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

echo @@@@@@@@@@@@@@@@@@@@@@
echo @ Recreating slaves
echo @@@@@@@@@@@@@@@@@@@@@@
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/centos-72-litecore-build:20191203 mobile-litecore-linux 6501 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/centos-69-litecore-build:20191224 mobile-litecore-centos6 6505 mobile.jenkins.couchbase.com
