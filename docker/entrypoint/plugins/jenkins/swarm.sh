# Entrypoint when container is running as a Jenkins agent using Jenkins
# Swarm.

#
# THIS IS A FINAL PLUGIN. It will not return control to the entrypoint
# script.
#

#
# THIS PLUGINS INSTALLS A HEALTHCHECK. Ensure your container is run with
# the healthcheck command set to `["CMD", "/tmp/healthcheck.sh"]` as
# documented in the top-level README.
#

# It expects the following environment variables to be set:
#
#   JENKINS_URL (url of Jenkins)
#   JENKINS_TUNNEL (OPTIONAL; if specified, used as -tunnel arg to swarm jar)
#   JENKINS_AGENT_EXECUTORS (defaults to 1)
#   JENKINS_AGENT_NAME (base name; will have container ID appended)
#   JENKINS_AGENT_LABELS
#
# In addition it expects the following files to exist:
#
#   /run/secrets/jenkins_username
#   /run/secrets/jenkins_password

# This script saves various info in /tmp/swarm-agent which are
# referenced by the `swarm` healthcheck script.
SWARM_AGENT_DIR=/tmp/swarm-agent
mkdir -p ${SWARM_AGENT_DIR}

# Plugins we depend on:
invoke_plugin generic/agent_path

# Assert our requirements:
chk_set JENKINS_URL JENKINS_AGENT_NAME JENKINS_AGENT_LABELS
chk_file /run/secrets/jenkins_username /run/secrets/jenkins_password


status Downloading Jenkins swarm client
curl -fsSL -o /tmp/swarm-client.jar ${JENKINS_URL}/swarm/swarm-client.jar

if [ ! -z "${JENKINS_TUNNEL}" ]; then
    TUNNEL_ARG="-tunnel ${JENKINS_TUNNEL}"
fi

# Save some information about the agent for the healthcheck script
# or anything else that might want it.
AGENT_NAME="${JENKINS_AGENT_NAME}-$(hostname)"
echo "${AGENT_NAME}" > ${SWARM_AGENT_DIR}/jenkins_agent_name
echo "${JENKINS_URL}" > ${SWARM_AGENT_DIR}/jenkins_url
echo "${JENKINS_AGENT_LABELS}" > ${SWARM_AGENT_DIR}/jenkins_agent_labels

# Install our specific healthcheck script
install_healthcheck swarm

# We don't want the child to immediately die when the container is
# stopped, so intercept SIGTERM and then run the healthcheck to see
# if it's OK to die
keepalive() {
    echo "Agent ${AGENT_NAME} stop requested!"
    sudo touch ${SWARM_AGENT_DIR}/jenkins_agent_stop_requested
    /tmp/healthcheck.sh
}
trap keepalive TERM

status "Agent ${AGENT_NAME} starting up; logs follow..."

# Pre-create the swarm agent logfile - this avoids issues with tail failing
# if the file doesn't exist yet.
touch ${SWARM_AGENT_DIR}/swarm-client.log

# Execute swarm client. We use `env` to set the PATH to `agent_path` as
# specified by the generic/agent_path plugin.
env PATH=${agent_path} java $JAVA_OPTS \
    -jar /tmp/swarm-client.jar \
    -fsroot /home/couchbase/jenkins \
    -master "${JENKINS_URL}" \
    ${TUNNEL_ARG} \
    -mode exclusive \
    -executors "${JENKINS_AGENT_EXECUTORS:-1}" \
    -name "${AGENT_NAME}" \
    -disableClientsUniqueId \
    -deleteExistingClients \
    -labels "${JENKINS_AGENT_LABELS} ${CONTAINER_TAG//\//_}" \
    -retry 5 \
    -noRetryAfterConnected \
    -username "$(cat /run/secrets/jenkins_username)" \
    -passwordFile /run/secrets/jenkins_password \
    >& ${SWARM_AGENT_DIR}/swarm-client.log &

# Save PID of child for healthcheck/reaping
PID=$!
echo "${PID}" > ${SWARM_AGENT_DIR}/jenkins_agent_pid

# Send logs to stdout for "docker service logs"
tail -f ${SWARM_AGENT_DIR}/swarm-client.log &

# Also, we no longer want to exit THIS script on any error
set +e

# Loop forever, until the child process is actually gone
while test -d /proc/${PID}; do
   wait $PID
done
status "Agent ${AGENT_NAME} exiting"
exit
