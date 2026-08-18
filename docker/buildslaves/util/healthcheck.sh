#!/bin/bash -e

MIN_FREE_GB=20
WORKSPACE=/home/couchbase/jenkins/workspace
NODE_OFFLINE_FILE=/home/couchbase/jenkins/workspace/node-offline
HEALTH_LOG_DIR=/home/couchbase/jenkins-agent-health
HEALTH_LOG_FILE=${HEALTH_LOG_DIR}/health.log
mkdir -p "${HEALTH_LOG_DIR}" 2>/dev/null || true

CURL_COMMON_OPTS=(
    --silent
    --fail
    --show-error
    --connect-timeout 3
    --max-time 5
    --retry 2
    --retry-delay 1
)

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

DOCKER_PATHS=(
    "$(command -v docker 2>/dev/null || true)"
    "/usr/bin/docker"
    "/usr/local/bin/docker"
)
for docker_bin in "${DOCKER_PATHS[@]}"; do
    if [ -x "$docker_bin" ]; then
        DOCKER_CMD="$docker_bin"
    fi
done

function node_online {
    ${SWARM_MODE} || return 0

    curl "${CURL_COMMON_OPTS[@]}" \
        -u "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/api/xml?tree=offline" \
        | grep -F -q 'offline>false<'
}

function node_busy {
    ${SWARM_MODE} || return 0

    curl "${CURL_COMMON_OPTS[@]}" \
        -u "${JENKINS_USERNAME}:${JENKINS_PASSWORD}" \
        "${JENKINS_URL}/computer/${JENKINS_AGENT_NAME}/api/xml?tree=executors%5Bidle%5D,oneOffExecutors%5Bidle%5D" \
        | grep -F -q 'idle>false<'
}

function log_health_event {
    local message="$1"
    {
        echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] ${message}"
        echo "--- docker stats --no-stream --all ---"
        sudo ${DOCKER_CMD} stats --no-stream --all 2>/dev/null || true
    } 2>&1 | tee -a "${HEALTH_LOG_FILE}" || true
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

function cleanup_docker_resources {
    if [[ -z ${DOCKER_CMD} ]]; then
        return 0
    fi

    # Remove stopped containers older than 8h. The status filter already
    # excludes any active container, and "docker rm" without -f refuses to
    # remove a running one regardless.
    echo "Healthcheck: removing stopped containers older than 8h" 2>&1 | tee -a "${HEALTH_LOG_FILE}"
    check=$(date -u --date "-8 hours" +"%s")
    stopped_ids=$(sudo ${DOCKER_CMD} ps -a --filter 'status=exited' --filter 'status=created' --filter 'status=dead' --format '{{.ID}}')
    if [ -n "${stopped_ids}" ]; then
        for sid in ${stopped_ids}; do
            created=$(sudo ${DOCKER_CMD} inspect -f '{{.Created}}' "${sid}" 2>/dev/null || true)
            created_epoch=$(date --date="${created}" +'%s' 2>/dev/null || true)
            if [ -z "${created_epoch}" ] || [ ${check} -lt ${created_epoch} ]; then
                continue
            fi

            sudo ${DOCKER_CMD} rm "${sid}" >/dev/null 2>&1 || true
        done
    fi

    # Remove images with no container (running or stopped) referencing them.
    echo "Healthcheck: removing unused docker images" 2>&1 | tee -a "${HEALTH_LOG_FILE}"
    all_images=$(sudo ${DOCKER_CMD} image ls -q | sort -u)
    if [ -n "${all_images}" ]; then
        for image_id in ${all_images}; do
            if sudo ${DOCKER_CMD} ps -a --filter "ancestor=${image_id}" -q | grep -q .; then
                continue
            fi
            sudo ${DOCKER_CMD} image rm "${image_id}" >/dev/null 2>&1 || true
        done
    fi

    # Remove dangling volumes (by definition unreferenced by any container).
    echo "Healthcheck: removing dangling volumes" 2>&1 | tee -a "${HEALTH_LOG_FILE}"
    dangling_volumes=$(sudo ${DOCKER_CMD} volume ls -qf dangling=true | sort -u)
    if [ -n "${dangling_volumes}" ]; then
        for vol in ${dangling_volumes}; do
            sudo ${DOCKER_CMD} volume rm "${vol}" >/dev/null 2>&1 || true
        done
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
        echo "Healthcheck: Removing oldest workspace: ${oldest}" 2>&1 | tee -a "${HEALTH_LOG_FILE}"
        rm -rf "$oldest"
    done
    popd
}

# This isn't really a "healthcheck" as we'll shoot ourselves in the head
# if it fails twice in a row.
if node_online; then
    rm -f ${NODE_OFFLINE_FILE}
else
    log_health_event "node is offline"
    test -e ${NODE_OFFLINE_FILE} && sudo kill -9 1
    touch ${NODE_OFFLINE_FILE}
fi

# Likewise, not a healthcheck. Shoot the agent in the head if we've been
# requested to shut down and we're not currently executing any jobs.
if [ -f /var/run/jenkins_agent_stop_requested ]; then
    if ! node_busy; then
        log_health_event "killing idle agent ${JENKINS_AGENT_NAME} per request"
        sudo kill -TERM ${JENKINS_AGENT_PID}
        exit
    fi
fi

# First check if space on the root volume is low and run cleanup if needed
root_free_space_ok || cleanup_docker_resources

# Then check workspace storage and clean up if required
workspace_free_space_ok || remove_workspaces

# Finally ensure all resources are OK, exit with failure if any check fails
if ! root_free_space_ok || ! workspace_free_space_ok || ! memory_ok; then
    log_health_event "resource checks failed; healthcheck exiting with status 1"
    exit 1
fi
