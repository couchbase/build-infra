#!/bin/bash -e

MIN_FREE_GB=20
WORKSPACE=/home/couchbase/jenkins/workspace

# Load some useful files (swarm mode only)
if [ -e /var/run/jenkins_agent_name ]; then
    SWARM_MODE=true
    JENKINS_URL=$(cat /var/run/jenkins_master_url)
    JENKINS_AGENT_NAME=$(cat /var/run/jenkins_agent_name)
    JENKINS_AGENT_PID=$(cat /var/run/jenkins_agent_pid)
    JENKINS_USERNAME=$(cat /run/secrets/jenkins_master_username)
    JENKINS_PASSWORD=$(cat /run/secrets/jenkins_master_password)
else
    SWARM_MODE=false
fi

function node_online {
    ${SWARM_MODE} || return 0

    curl --silent --fail \
        -u "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/api/xml?tree=offline" \
        | fgrep -q 'offline>false<'
}

function node_busy {
    ${SWARM_MODE} || return 0

    curl --silent --fail \
        -u "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/api/xml?tree=executors%5Bidle%5D,oneOffExecutors%5Bidle%5D" \
        | fgrep -q 'idle>false<'
}

function workspace_free_space_ok {
    test -d "${WORKSPACE}" || return 0
    # 4th field is "Available"
    local free_kb=$(df -kP "${WORKSPACE}" | tail -1 | awk '{print $4}')
    local min_free_kb=$((MIN_FREE_GB*1024*1024))

    if [ $free_kb -gt $min_free_kb ]; then
        return 0
    else
        return 1
    fi
}

function root_free_space_ok {
    # 4th field is "Available"
    local free_kb=$(df -kP / | tail -1 | awk '{print $4}')
    local min_free_kb=$((MIN_FREE_GB*1024*1024))

    if [ $free_kb -gt $min_free_kb ]; then
        return 0
    else
        return 1
    fi
}
function memory_ok {
    local error_pattern='unable to create native thread: possibly out of memory or process/resource limits reached'

    if [ -f "/var/log/swarm-client.log" ]; then
        grep "$error_pattern" /var/log/swarm-client.log && return 1
    fi

    if [ -f "/home/couchbase/swarmclient0.log" ]; then
        grep "$error_pattern" /home/couchbase/swarmclient0.log && return 1
    fi

    return 0
}

function docker_prune {
    # If we got here we're still short on space, so try a prune
    # (if docker is present and working)
    if (command -v docker && sudo docker ps) &>/dev/null ; then
        echo "Healthcheck: Running docker system prune"
        sudo docker system prune -a -f
    fi
}

function remove_workspaces {
    # Time-sorted list of directories. Strip off the *first* line
    # (so we don't attempt to remove the newest directory, which
    # may represent a running job), and then pick the *last* line
    # (which should be the oldest workspace directory). If this
    # results in no entries, there's nothing safe for us to remove,
    # so mark the container unhealthy.
    test -d "${WORKSPACE}" || return 0
    pushd "${WORKSPACE}"
    while ! workspace_free_space_ok; do
        oldest=$(ls -1t | grep -v workspaces.txt | tail -n +2 | tail -n -1)
        if [[ -z "$oldest" ]]; then
            break
        fi
        echo "Healthcheck: Removing oldest workspace: ${oldest}"
        rm -rf "$oldest"
    done
    popd
}

# This isn't really a "healthcheck" as we'll shoot ourselves in the head
# if it fails twice in a row.
if node_online; then
    rm -f /var/run/node-offline
else
    test -e /var/run/node-offline && sudo kill -9 1
    touch /var/run/node-offline
fi

# Likewise, not a healthcheck. Shoot the agent in the head if we've been
# requested to shut down and we're not currently executing any jobs.
if [ -f /var/run/jenkins_agent_stop_requested ]; then
    if ! node_busy; then
        echo "Healthcheck: Killing idle agent ${JENKINS_AGENT_NAME} per request"
        kill -TERM ${JENKINS_AGENT_PID}
        exit
    fi
fi

# First check if space on the root volume is low and run docker prune if needed
root_free_space_ok || docker_prune

# Then check workspace storage and clean up if required
workspace_free_space_ok || remove_workspaces

# Finally ensure all resources are OK, exit with failure if any check fails
if ! root_free_space_ok || ! workspace_free_space_ok || ! memory_ok; then
    exit 1
fi
