#!/bin/bash

mkdir -p /home/couchbase/.docker
if [ -e /ssh/docker-push-config.json ]
then
    cp -a /ssh/docker-push-config.json /home/couchbase/.docker/config.json
fi
chown -R couchbase:couchbase /home/couchbase/.docker
