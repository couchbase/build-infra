#!/bin/bash -ex

# Here is where to add any expiry-policy commands you want
function expire-images() {
    ./deckschrubber -day 2 -registry https://build-docker.couchbase.com/ -repo 'couchbase/server-toy' -tag 'analytics-jenkins' -repos 1000
    ./deckschrubber -day 90 -latest 5 -registry https://build-docker.couchbase.com/ -repo 'couchbase/couchbase-(admission|exporter|operator).*' -repos 100
}

# Always re-enable read/write mode on the registry when we're done
function finish() {
    docker --host mega4.build.couchbase.com service update --env-add REGISTRY_STORAGE_MAINTENANCE_READONLY='{"enabled": false}'  docker_registry
    rm -f deckschrubber
}
trap finish EXIT

# Download cleanup tool and run it with our prefered expiry configurations
curl -LO https://github.com/fraunhoferfokus/deckschrubber/releases/download/v0.6.0/deckschrubber
chmod 755 deckschrubber
expire-images

# Set the registry read-only and launch the "cleanup" garbage-collection service
docker --host mega4.build.couchbase.com service update --env-add REGISTRY_STORAGE_MAINTENANCE_READONLY='{"enabled": true}'  docker_registry
docker --host mega4.build.couchbase.com service scale -d docker_registry-cleanup=1

# Wait for the garbage-collection service to complete
state=Running
while [ "$state" != "Complete" -a "$state" != "Failed" ]; do
    sleep 1
    state=$(docker --host mega4.build.couchbase.com service ps --format '{{ index (split .CurrentState " ") 0 }}' docker_registry-cleanup)
done

# Report error
if [ "$state" = "Failed" ]; then
    echo "docker_registry-cleanup failed; might not have garbage-collected fully"
    exit 1
fi

# Remove the cleanup service
docker --host mega4.build.couchbase.com service scale -d docker_registry-cleanup=0



