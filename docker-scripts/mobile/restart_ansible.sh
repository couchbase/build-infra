#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Hosted on mega3

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/ansible-slave:20180312 ansible-slave-mobile 2998 mobile.jenkins.couchbase.com

