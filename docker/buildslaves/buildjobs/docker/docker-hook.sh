#!/bin/bash -e

# Set up for Docker pushing
mkdir /home/couchbase/.docker
chmod 700 /home/couchbase/.docker
if [ -e /home/couchbase/.ssh/docker-push-config.json ]; then
    cp /home/couchbase/.ssh/docker-push-config.json /home/couchbase/.docker/config.json
    chmod 600 /home/couchbase/.docker/config.json
fi
chown -R couchbase:couchbase /home/couchbase/.docker
