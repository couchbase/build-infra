#!/bin/bash


# NOTE: This script is no longer used as-is. However the same command here
# is embedded in the Execute Shell step of
#
# http://sdk.jenkins.couchbase.com/job/recreate-special-slave/
#
# So I leave this script here for future reference.


start_special_slave() {
    slave_name=$1
    slave_labels=$2
    image=$3

    docker run -d --privileged --restart=unless-stopped \
        --name ${slave_name} \
        -e JENKINS_MASTER=http://sdk-swarm.build.couchbase.com:8080/ \
        -e JENKINS_SLAVE_NAME=${slave_name} \
        -e JENKINS_SLAVE_LABELS="${slave_labels}" \
        -v /home/couchbase/SPECIAL_SLAVES/jenkins_master_username:/run/secrets/jenkins_master_username \
        -v /home/couchbase/SPECIAL_SLAVES/jenkins_master_password:/run/secrets/jenkins_master_password \
        ${image} \
        swarm
}

start_special_slave cowbuilder cowbuilder couchbasebuild/sdk-cowbuilder:latest
start_special_slave mock mock couchbasebuild/sdk-mock:latest
