#!/bin/bash

# These are currently all hosted on mega2

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

echo @@@@@@@@@@@@@@@@@@@@@@
echo @ Recreating slaves
echo @@@@@@@@@@@@@@@@@@@@@@
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/centos-69-litecore-build:20191224 mobile-litecore-centos6-01 6505 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/centos-69-litecore-build-gcc:20200505 mobile-litecore-centos6-gcc-01 6507 mobile.jenkins.couchbase.com
