#!/bin/bash

MIN_FREE_GB=20
WORKSPACE=/home/couchbase/jenkins/workspace

function free_space_ok {
    local free_kb=$(df -k --output=avail "${WORKSPACE}" | tail -1)
    local min_free_kb=$((MIN_FREE_GB*1024*1024))

    if [ $free_kb -gt $min_free_kb ]; then
        return 0
    else
        return 1
    fi
}

function memory_ok {
    if [ -f "/home/couchbase/jenkins/remoting/logs/remoting.log.0" ]; then
        grep 'unable to create native thread: possibly out of memory or process/resource limits reached' /var/log/swarm-client.log && return 1
    fi
    return 0
}

function docker_prune {
    # If we got here we're still short on space, so try a prune
    # (if docker is present and working)
    if (command -v docker && sudo docker ps) &>/dev/null ; then
        sudo docker system prune -f
    fi
    return $(free_space_ok)
}

function remove_workspaces {
    # Time-sorted list of directories. Strip off the *first* line
    # (so we don't attempt to remove the newest directory, which
    # may represent a running job), and then pick the *last* line
    # (which should be the oldest workspace directory). If this
    # results in no entries, there's nothing safe for us to remove,
    # so mark the container unhealthy.
    if [[ -d "${WORKSPACE}" ]]; then
        pushd "${WORKSPACE}"
        oldest=$(ls -1t | tail -n +2 | tail -n -1)
        if [[ -z "$oldest" ]]; then
            return 1
        fi

        time rm -rf "$oldest"
        popd "${WORKSPACE}"
        return $(free_space_ok)
    fi
}

free_space_ok || docker_prune || remove_workspaces || exit 1
memory_ok || exit 1
