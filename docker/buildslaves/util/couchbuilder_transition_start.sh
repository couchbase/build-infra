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
# The following environment variables are also used to compose the
# path profile data will be synchronised from
#
#   NODE_CLASS   (e.g. build, cv)
#   NODE_PRODUCT (e.g. couchbase-server)
#
# In addition it expects the following Docker secret to exist:
#
#   /run/secrets/profile_ssh_key

if [ -d /ssh ] && [ "$(ls -A /ssh)" ]
then
    mkdir -p /home/couchbase/.ssh
    cp -a /ssh/* /home/couchbase/.ssh
fi
chown -R couchbase:couchbase /home/couchbase/.ssh
chmod 600 /home/couchbase/.ssh/*


# We need to ensure these env vars are available in the exported function, and the script string which is evaled or execed via su
export profile_port="4000"
export profile_host="profiledata.build.couchbase.com"

add_hostkeys() {
    hostkeys="$(ssh-keyscan -p ${profile_port} ${profile_host})"
    for key in "$hostkeys"
    do
      if ! cat /home/couchbase/.ssh/known_hosts 2>/dev/null | grep "$key"
      then
        echo "$key" >> /home/couchbase/.ssh/known_hosts
      fi
    done
}

export -f add_hostkeys

# Handle invocations by the ECS plugin
[[ "$1" == "-url" || "$1" == "swarm" ]] && {
  mkdir -p /run/secrets
  echo "${profiledata_key}" > /run/secrets/profile_sync
}

if [ -f /run/secrets/profile_sync -a ! -e "${NODE_CLASS}" -a ! -e "${NODE_PRODUCT}" ]
then
  echo "###########################"
  echo "# Populating profile data #"
  echo "###########################"

  # Ensure the host where the profile data lives is in our known_hosts before synchronisation. We also
  # have to set permissions on directories here as we can only specify perms on files in the profile container
  start_cmd="mkdir -p ~/.ssh \
    && add_hostkeys \
    && rsync --progress --archive --backup --executability --no-o --no-g -e \"ssh -p ${profile_port} -i /run/secrets/profile_sync -o StrictHostKeyChecking=no\" couchbase@${profile_host}:${NODE_PRODUCT}/${NODE_CLASS}/linux/ /home/couchbase/ \
    && ([ -d ~/.ssh ] && chmod 00700 ~/.ssh) \
    && ([ -d ~/.gpg ] && chmod 00700 ~/.gpg)"

  # we could concievably be running the container as root or couchbase, let's try
  # to populate the profile data correctly either way
  if [ "$(whoami)" = "couchbase" ]
  then
    sudo chmod 600 /run/secrets/profile_sync
    sudo chown couchbase:couchbase /run/secrets/profile_sync
    eval $start_cmd
  else
    chmod 600 /run/secrets/profile_sync
    chown couchbase:couchbase /run/secrets/profile_sync
    su couchbase -c "$start_cmd"
  fi
fi

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

# Finally, if any files exist in /home/couchbase/.gpg/
# (and the gpg command is available), those files will be imported into
# the couchbase user's gpg keychain.

command -v gpg >/dev/null 2>&1 && {
    shopt -s nullglob
    for gpgkey in /home/couchbase/.gpg/* /run/secrets/*.gpgkey
    do
        echo Importing ${gpgkey} ...
        sudo -u couchbase -H gpg --import ${gpgkey}
    done
    shopt -u nullglob
}

# if first argument is "swarm", run the (Jenkins) swarm jar with any arguments
[[ "$1" == "swarm" ]] && {
    unset profiledata_key

    AGENT_MODE=${AGENT_MODE:-exclusive}
    jenkins_user=$(echo -n ${jenkins_user:-$(cat /run/secrets/jenkins_master_username)} | xargs)
    jenkins_password=$(echo -n ${jenkins_password:-$(cat /run/secrets/jenkins_master_password)} | xargs)
    shift

    exec sudo -u couchbase --set-home --preserve-env \
       env -u jenkins_user -u jenkins_password -u SUDO_UID -u SUDO_GID -u SUDO_USER -u SUDO_COMMAND \
       PATH=/usr/local/bin:/usr/bin:/bin \
       java $JAVA_OPTS \
       -jar /usr/local/lib/swarm-client.jar \
       -fsroot "${JENKINS_SLAVE_ROOT:-/home/couchbase/jenkins}" \
       -master "${JENKINS_MASTER}" \
       -mode ${AGENT_MODE} \
       -executors "${JENKINS_SLAVE_EXECUTORS:-1}" \
       -name "${JENKINS_SLAVE_NAME}-$(hostname)" \
       -disableClientsUniqueId \
       -deleteExistingClients \
       -labels "${JENKINS_SLAVE_LABELS}" \
       -retry 5 \
       -username "${jenkins_user}" \
       -password "${jenkins_password}"
    exit
}

# if first argument is "default", for backwards-compatibility start sshd
# (as new, long-running, foreground process)
[[ "$1" == "default" ]] && {
    exec /usr/sbin/sshd -D
    exit
}

# Handle invocations by the ECS plugin
[[ "$1" == "-url" ]] && {
  unset profiledata_key
  unset jenkins_user
  unset jenkins_password
  URL="-url $2"
  TUNNEL="-tunnel $4"
  OPT_JENKINS_SECRET=$5
  OPT_JENKINS_AGENT_NAME=$6
  JAVA_BIN=java

  if $(sudo --help &>/dev/null)
  then
      exec sudo -u couchbase --set-home --preserve-env \
        env -u profiledata_key -u SUDO_UID -u SUDO_GID -u SUDO_USER -u SUDO_COMMAND \
        PATH=/usr/local/bin:/usr/bin:/bin \
        $JAVA_BIN $JAVA_OPTS -cp /usr/share/jenkins/agent.jar hudson.remoting.jnlp.Main -headless $TUNNEL $URL $WORKDIR $WEB_SOCKET $DIRECT $PROTOCOLS $INSTANCE_IDENTITY $OPT_JENKINS_SECRET $OPT_JENKINS_AGENT_NAME
  else
      exec sudo -E -u couchbase \
        env -u profiledata_key -u SUDO_UID -u SUDO_GID -u SUDO_USER -u SUDO_COMMAND \
        PATH=/usr/local/bin:/usr/bin:/bin \
        $JAVA_BIN $JAVA_OPTS -cp /usr/share/jenkins/agent.jar hudson.remoting.jnlp.Main -headless $TUNNEL $URL $WORKDIR $WEB_SOCKET $DIRECT $PROTOCOLS $INSTANCE_IDENTITY $OPT_JENKINS_SECRET $OPT_JENKINS_AGENT_NAME
  fi
  exit
}

# If argument is not 'swarm', assume user want to run their own process,
# for example a `bash` shell to explore this image
exec "$@"
