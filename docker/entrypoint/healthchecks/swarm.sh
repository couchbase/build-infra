#!/bin/bash -e

# Healthcheck for Jenkins Swarm agents running in Docker Swarm. This
# script will be installed by the `jenkins/swarm` universal-entrypoint
# plugin, and its operation is closely tied to that plugin as it depends
# on several files that are set up by that plugin.

MIN_FREE_GB=20
WORKSPACE=/home/couchbase/jenkins/workspace
SWARM_AGENT_DIR=/tmp/swarm-agent

# Load some useful files
JENKINS_URL=$(cat ${SWARM_AGENT_DIR}/jenkins_url)
JENKINS_AGENT_NAME=$(cat ${SWARM_AGENT_DIR}/jenkins_agent_name)
JENKINS_AGENT_PID=$(cat ${SWARM_AGENT_DIR}/jenkins_agent_pid)
JENKINS_USERNAME=$(cat /run/secrets/jenkins_username)
JENKINS_PASSWORD=$(cat /run/secrets/jenkins_password)

function node_online {
    curl --silent --fail \
        -u "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/api/xml?tree=offline" \
        | grep -F -q 'offline>false<'
}

function node_busy {
    curl --silent --fail \
        -u "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/api/xml?tree=executors%5Bidle%5D,oneOffExecutors%5Bidle%5D" \
        | grep -F -q 'idle>false<'
}

function free_space_ok {
    test -d "${WORKSPACE}" || return 0
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
        grep 'unable to create native thread: possibly out of memory or process/resource limits reached' ${SWARM_AGENT_DIR}/swarm-client.log && return 1
    fi
    return 0
}

function docker_prune {
    # If we got here we're still short on space, so try a prune
    # (if docker is present and working)
    if (command -v docker && docker ps) &>/dev/null ; then
        docker system prune -f
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
    test -d "${WORKSPACE}" || return 0
    pushd "${WORKSPACE}"
    while ! free_space_ok; do
        oldest=$(ls -1t | grep -v workspaces.txt | tail -n +2 | tail -n -1)
        if [[ -z "$oldest" ]]; then
            return 1
        fi

        rm -rf "$oldest"
    done
    popd
    return 0
}

# This isn't really a "healthcheck" as we'll shoot ourselves in the head
# if it fails twice in a row.
if node_online; then
    rm -f ${SWARM_AGENT_DIR}/node-offline
else
    test -e ${SWARM_AGENT_DIR}/node-offline && sudo kill -9 1
    touch ${SWARM_AGENT_DIR}/node-offline
fi

# Likewise, not a healthcheck. Shoot the agent in the head if we've been
# requested to shut down and we're not currently executing any jobs.
if [ -f ${SWARM_AGENT_DIR}/jenkins_agent_stop_requested ]; then
    if ! node_busy; then
        echo "Healthcheck: Killing idle agent ${JENKINS_AGENT_NAME} per request"
        kill -TERM ${JENKINS_AGENT_PID}
        exit
    fi
fi

free_space_ok || docker_prune || remove_workspaces || exit 1
memory_ok || exit 1
