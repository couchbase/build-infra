#!/bin/bash

# These are currently all hosted on mega

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

echo @@@@@@@@@@@@@@@@@@@@@@
echo @ Recreating slaves
echo @@@@@@@@@@@@@@@@@@@@@@
${SCRIPTPATH}/../restart_jenkinsdocker.py couchbasebuild/centos-72-litecore-build:20190926 mobile-litecore-linux 6501 mobile.jenkins.couchbase.com
