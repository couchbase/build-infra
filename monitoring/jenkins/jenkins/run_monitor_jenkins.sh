#!/bin/bash -e

# Ensure we have the latest image
docker pull couchbasebuild/jenkins_monitor:latest

echo
echo "Running basic monitoring across build-team-managed Jenkins servers..."
echo

docker run --rm -u couchbase \
    -w /home/couchbase/jenkins_monitor \
    -v /home/couchbase/jenkins_monitor/jenkins_monitor.json:/etc/jenkins_monitor.json \
    couchbasebuild/jenkins_monitor
