#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Hosted on mega2

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/clamav-slave:20180507 mobile-clamav-01 2888 mobile.jenkins.couchbase.com

