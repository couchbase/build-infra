#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Hosted on mega3

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/ansible-agent:20260116 ansible-agent-mobile 2998 mobile.jenkins.couchbase.com
