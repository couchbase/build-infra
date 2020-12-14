#!/bin/bash

if [[ ! -d /home/couchbase/jenkins/workspace ]]; then
    # No workspace directory yet - nothing to check
    exit 0
fi

cd /home/couchbase/jenkins/workspace

while true; do
    # Check current disk space. If it's greater than (somewhat
    # arbitrarily) 20 GB, we're good.
    avail=$(df -k --output=avail . | tail -1)
    if [[ "$avail" -gt 20000000 ]]; then
        echo "Disk space is OK"
        exit 0
    fi

    # Time-sorted list of directories. Strip off the *first* line
    # (so we don't attempt to remove the newest directory, which
    # may represent a running job), and then pick the *last* line
    # (which should be the oldest workspace directory). If this
    # results in no entries, there's nothing safe for us to remove,
    # so mark the container unhealthy.

    oldest=$(ls -1t | tail +2 | tail -1)
    if [[ -z "$oldest" ]]; then
        echo "No more workspaces to delete - bad!"
       	exit 1
    fi

    echo "Removing $oldest"
    time rm -rf "$oldest"
done
