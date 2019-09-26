#!/bin/bash

# These are currently all hosted on mega

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-workspace couchbasebuild/ubuntu1604-sgw-build:20181204 mobile-sgw-ubuntu16 2323 mobile.jenkins.couchbase.com

echo "docker stop mobile-sgw-centos6"
docker stop mobile-sgw-centos6
echo "docker rm mobile-sgw-centos6"
docker rm mobile-sgw-centos6
docker run --name="mobile-sgw-centos6" -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --volume=/home/couchbase/latestbuilds:/latestbuilds \
        --restart=unless-stopped \
        -p 2320:22 -d ceejatec/centos-65-sgw-build:20170627

container_name="mobile-sgw-centos70"
container=$(docker ps | grep $container_name | awk -F\" '{ print $1 }')
echo "container: $container"
if [[ $container ]]
then
    echo "docker rm -f $container_name"
    docker rm -f $container_name
fi

docker run --name=$container_name -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --volume=/home/couchbase/latestbuilds:/latestbuilds \
        --restart=unless-stopped \
        -p 2322:22 -d ceejatec/centos-70-sgw-build:20180214

container_name="mobile-sgw-ubuntu14"
container=$(docker ps | grep $container_name | awk -F\" '{ print $1 }')
echo "container: $container"
if [[ $container ]]
then
    echo "docker rm -f $container_name"
    docker rm -f $container_name
fi

# Port number 23xx used by SGW
docker run --name=$container_name -v /home/couchbase/jenkinsdocker-ssh:/ssh \
        --volume=/home/couchbase/latestbuilds:/latestbuilds \
        --restart=unless-stopped \
        -p 2321:22 -d ceejatec/ubuntu1404-sgw-build:20180214
