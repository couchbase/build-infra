#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

# Currently these slaves are all hosted on mega2

# cv.jenkins slaves
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts couchbasebuild/zz-lightweight:20210225 cv-zz-lightweight 3224 cv.jenkins.couchbase.com &

wait
echo "All done!"
exit 0

