#!/bin/bash

# These are currently all hosted on mega1

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

echo @@@@@@@@@@@@@@@@@@@@@@
echo @ Recreating slaves
echo @@@@@@@@@@@@@@@@@@@@@@
${SCRIPTPATH}/../restart_jenkinsdocker.py couchbasebuild/zz-lightweight:20200812 zz-mobile-lightweight 2423 mobile.jenkins.couchbase.com
