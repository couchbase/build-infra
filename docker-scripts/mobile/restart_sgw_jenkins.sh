#!/bin/bash

# These are currently all hosted on mega1

pushd `dirname $0` > /dev/null
SCRIPTPATH=`pwd -P`
popd > /dev/null

${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts --no-workspace couchbasebuild/ubuntu1604-sgw-build:20181204 mobile-sgw-ubuntu16-01 2323 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts --no-workspace couchbasebuild/centos6-sgw-build:20190926 mobile-sgw-centos6-01 2320 mobile.jenkins.couchbase.com
${SCRIPTPATH}/../restart_jenkinsdocker.py --no-std-mounts --no-workspace couchbasebuild/centos7-sgw-build:20200319 mobile-sgw-centos7-01 2322 mobile.jenkins.couchbase.com

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
        --restart=unless-stopped \
        -p 2321:22 -d couchbasebuild/ubuntu1404-sgw-build:20190926
