#!/bin/bash

MIN_FREE_GB=20
WORKSPACE=/home/couchbase/jenkins/workspace

function check_free_space {
    if [[ ! -d "${WORKSPACE}" ]]; then
        # No workspace directory yet - nothing to check
        exit 0
    fi

    local free_kb=$(df -k --output=avail "${WORKSPACE}" | tail -1)
    local min_free_kb=$((MIN_FREE_GB*1024*1024))

    if [ $free_kb -gt $min_free_kb ]; then
        echo "Disk space is OK"
        exit 0
    fi
}

while true; do
    # Check free space (a happy check_free_space will exit 0)
    check_free_space

    # If we got here we're still short on space, so try a prune
    # (if docker is present and working)
    if (command -v docker && docker ps) &>/dev/null ; then
        docker system prune -f
        check_free_space
    fi

    # Either we couldn't do the prune, or it didn't help if we got
    # here. Removing old workspaces is next...

    # Time-sorted list of directories. Strip off the *first* line
    # (so we don't attempt to remove the newest directory, which
    # may represent a running job), and then pick the *last* line
    # (which should be the oldest workspace directory). If this
    # results in no entries, there's nothing safe for us to remove,
    # so mark the container unhealthy.

    oldest=$(ls -1t | tail +2 | tail -1)
    if [[ -z "$oldest" ]]; then
        echo "FATAL: No more workspaces to delete and docker system prune didn't help"
        exit 1
    fi

    echo "Removing $oldest"
    time rm -rf "$oldest"
done
