#!/bin/sh

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/zz-lightweight:20210421 zz-analytics-lightweight-01 2212 analytics.jenkins.couchbase.com

echo "All done!"
