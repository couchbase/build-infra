#!/bin/bash

# These are currently all hosted on mega3

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts --no-workspace couchbasebuild/ubuntu1604-sgw-build:20181204 mobile-sgw-ubuntu16-01 2323 mobile.jenkins.couchbase.com
