#!/bin/bash

# These are currently all hosted on mega1

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts --no-workspace couchbasebuild/ubuntu1804-mobile-lite-android:20200812 mobile-android-ubuntu18-01 6502 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts --no-workspace couchbasebuild/ubuntu1804-mobile-lite-android:20200812 mobile-android-ubuntu18-02 6503 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts --no-workspace couchbasebuild/ubuntu1804-mobile-lite-android:20200812 mobile-android-ubuntu18-03 6504 mobile.jenkins.couchbase.com
