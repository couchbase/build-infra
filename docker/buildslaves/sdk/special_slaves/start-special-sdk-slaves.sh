#!/bin/bash


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

start_special_slave cowbuilder cowbuilder couchbasebuild/sdk-ubuntu14-build:20180906
start_special_slave mock mock couchbasebuild/sdk-centos7-build:20180906

