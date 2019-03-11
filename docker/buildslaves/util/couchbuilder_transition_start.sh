#!/bin/bash

# Script intended to be ENTRYPOINT for Couchbase build containers
# based on Jenkins Swarm and running on Docker Swarm, OR as a
# "traditional" ssh-based based slave.

# When invoked as a Jenkins Swarm slave, it expects
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

# First, copy any files in /ssh to /home/couchbase/.ssh, changing ownership to
# user couchbase and maintaining permissions. This is for "old-school" slaves
# which aren't using Docker Swarm secrets exclusively yet.
if [ -d /ssh ] && [ "$(ls -A /ssh)" ]
then
    cp -a /ssh/* /home/couchbase/.ssh
fi
chown -R couchbase:couchbase /home/couchbase/.ssh
chmod 600 /home/couchbase/.ssh/*

# Hooks for build image-specific steps
shopt -s nullglob
for hook in /usr/sbin/couchhook.d/*
do
    "${hook}"
done

# Older single hook for build image-specific steps
if [[ -e /usr/sbin/couchhook.sh ]]
then
    /usr/sbin/couchhook.sh
fi

# if first argument is "swarm", run the (Jenkins) swarm jar with any arguments
[[ "$1" == "swarm" ]] && {
    shift

    exec sudo -u couchbase -H \
       env -u SUDO_UID -u SUDO_GID -u SUDO_USER -u SUDO_COMMAND \
       PATH=/usr/local/bin:/usr/bin:/bin \
       java $JAVA_OPTS \
       -jar /usr/local/lib/swarm-client.jar \
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

# if first argument is "default", for backwards-compatibility start sshd
# (as new, long-running, foreground process)
[[ "$1" == "default" ]] && {
    exec /usr/sbin/sshd -D
}

# If argument is not 'swarm', assume user want to run their own process,
# for example a `bash` shell to explore this image
exec "$@"
