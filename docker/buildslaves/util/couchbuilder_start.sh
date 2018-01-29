#!/bin/bash

# Script intended to be ENTRYPOINT for Couchbase build containers
# based on Jenkins Swarm and running on Docker Swarm. It expects
# the following environment variables to be set (by the Dockerfile
# or the service):
#
#   JENKINS_MASTER
#   JENKINS_SLAVE_ROOT (defaults to /home/couchbase/jenkins)
#   JENKINS_SLAVE_EXECUTORS (defaults to 1)
#   JENKINS_SLAVE_NAME (base name; will have container ID appended)
#   JENKINS_SLAVE_LABELS
#
# In addition it expects the following Docker secrets to exist:
#
#   /run/secrets/jenkins_master_username
#   /run/secrets/jenkins_master_password

# Hooks for build image-specific steps
shopt -s nullglob
for hook in /usr/sbin/couchhook.d/*
do
    "${hook}"
done

# if first argument is "swarm", run the (Jenkins) swarm jar with any arguments
[[ "$1" == "swarm" ]] && {
    shift

    exec java $JAVA_OPTS -jar /usr/local/lib/swarm-client.jar \
       -fsroot "${JENKINS_SLAVE_ROOT:-/home/couchbase/jenkins}" \
       -master "${JENKINS_MASTER}" \
       -mode exclusive \
       -executors "${JENKINS_SLAVE_EXECUTORS:-1}" \
       -name "${JENKINS_SLAVE_NAME}-$(hostname)" \
       -disableClientsUniqueId \
       -deleteExistingClients \
       -labels "${JENKINS_SLAVE_LABELS}" \
       -retry 5 \
       -username "$(cat /run/secrets/jenkins_master_username)" \
       -password "$(cat /run/secrets/jenkins_master_password)"
}

# If argument is not 'swarm', assume user want to run their own process,
# for example a `bash` shell to explore this image
exec "$@"
