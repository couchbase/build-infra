#!/bin/sh

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# slave for server+analytics CV, running on mega2
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/server-ubuntu16-build:20181125 ubuntu16-analytics-01 2211 analytics.jenkins.couchbase.com

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/zz-lightweight:20200812 zz-analytics-lightweight-01 2212 analytics.jenkins.couchbase.com

echo "All done!"

