#!/bin/bash

# These are currently all hosted on mega

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-workspace couchbasebuild/ubuntu1604-mobile-lite-android:20190318 mobile-lite-android    6502 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-workspace couchbasebuild/ubuntu1604-mobile-lite-android:20190318 mobile-lite-android-02 6503 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-workspace couchbasebuild/ubuntu1804-mobile-lite-android:20190620 mobile-lite-android-03 6504 mobile.jenkins.couchbase.com

docker rm -f mobile-light
docker run --name="mobile-light" -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --volume=/home/couchbase/latestbuilds:/latestbuilds \
        --restart=unless-stopped \
        -p 2300:22 -d ceejatec/ubuntu1404-mobile-android-docker:20160712

docker rm -f mobile-android
docker run --name="mobile-android" -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --restart=unless-stopped \
        -p 2422:22 -d ceejatec/ubuntu1404-mobile-android-docker:20180502

docker rm -f mobile-java
docker run --name="mobile-java" -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --restart=unless-stopped \
        -p 2424:22 -d ceejatec/ubuntu1404-mobile-android-docker:20160712

