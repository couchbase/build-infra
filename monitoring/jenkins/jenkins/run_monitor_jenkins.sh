#!/bin/bash -e

# Ensure we have the latest image
docker pull couchbasebuild/jenkins_monitor:20210329

# Needed for SQLite database
mkdir -p /home/couchbase/db
chmod 755 /home/couchbase/db

echo
echo "Running basic monitoring across build-team-managed Jenkins servers..."
echo

docker run --rm -u couchbase \
    -w /home/couchbase/jenkins_monitor \
    -v /home/couchbase/jenkins_monitor/jenkins_monitor.json:/etc/jenkins_monitor.json \
    -v /home/couchbase/db:/home/couchbase/db \
    couchbasebuild/jenkins_monitor:20210329 \
    monitor_jenkins -d -c /etc/jenkins_monitor.json
