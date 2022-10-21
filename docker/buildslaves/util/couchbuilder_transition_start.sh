#!/bin/bash -ex

# Script intended to be ENTRYPOINT for Couchbase build containers
# based on Jenkins Swarm and running on Docker Swarm, OR as a
# "traditional" ssh-based based slave.

# When invoked as a Jenkins Swarm slave, it expects
# the following environment variables to be set (by the Dockerfile
# or the service):
#
#   JENKINS_MASTER (url of Jenkins)
#   JENKINS_TUNNEL (OPTIONAL; if specified, used as -tunnel arg to swarm jar)
#   JENKINS_SLAVE_ROOT (defaults to /home/couchbase/jenkins)
#   JENKINS_SLAVE_EXECUTORS (defaults to 1)
#   JENKINS_SLAVE_NAME (base name; will have container ID appended)
#   JENKINS_SLAVE_LABELS
#
# In addition it expects the following Docker secrets to exist:
#
#   /run/secrets/jenkins_master_username
#   /run/secrets/jenkins_master_password
#
#
# Regardless of how it is invoked, if the following environment
# variables are set, they will be used to compose the path from which
# profile data will be pulled to configure the node
#
#   NODE_CLASS   (e.g. build, cv)
#   NODE_PRODUCT (e.g. couchbase-server)
#
# In that case, it expects the following Docker secret to exist:
#
#   /run/secrets/profile_ssh_key

mkdir -p /home/couchbase/.ssh
touch /home/couchbase/.ssh/known_hosts

if [ -d /ssh ] && [ "$(ls -A /ssh)" ]
then
    cp -a /ssh/* /home/couchbase/.ssh
fi

active_user=$(whoami)

# We need to let these fall through to a noop in case we hit mounts
sudo chown -R couchbase:couchbase /home/couchbase/.ssh || :
chmod -R 600 /home/couchbase/.ssh/* || :
chmod 700 /home/couchbase/.ssh || :

if [ -f /ssh/aws-credentials ]
then
    mkdir -p /home/couchbase/.aws
    printf "[default]\nregion=us-east-1\noutput=json" > /home/couchbase/.aws/config
    cp -a /ssh/aws-credentials /home/couchbase/.aws/credentials
    sudo chown -R couchbase:couchbase /home/couchbase/.aws
fi

# We need to ensure these env vars are available in the exported function, and the script string which is evaled or execed via su
export profile_port="4000"
export profile_host="profiledata.build.couchbase.com"

add_hostkeys() {
    hostkeys="$(ssh-keyscan -p ${profile_port} ${profile_host})"
    for key in "$hostkeys"
    do
      if ! grep "$key" /home/couchbase/.ssh/known_hosts &>/dev/null && :
      then
        echo "$key" >> /home/couchbase/.ssh/known_hosts
      fi
    done
}

export -f add_hostkeys

# Prep for profiledata
[[ "$1" == "-url" || "$1" == "swarm" ]] && {
  sudo mkdir -p /run/secrets
  if [ "${profiledata_key}" != "" -a ! -f /run/secrets/profile_sync ]
  then
    echo "${profiledata_key}" | sudo tee -a /run/secrets/profile_sync >/dev/null
  fi
}

if [ -f /run/secrets/profile_sync -a ! -e "${NODE_CLASS}" -a ! -e "${NODE_PRODUCT}" ]
then
  echo "###########################"
  echo "# Populating profile data #"
  echo "###########################"

  # Ensure the host where the profile data lives is in our known_hosts before synchronisation. We also
  # have to set permissions on directories here as we can only specify perms on files in the profile container
  start_cmd=" \
    mkdir -p ~/.ssh \
      && add_hostkeys \
      && for node_class in ${NODE_CLASS}; do \
           rsync --progress --archive --backup --executability --no-o --no-g \
           -e \"ssh -p ${profile_port} -i /run/secrets/profile_sync -o StrictHostKeyChecking=no\" \
           couchbase@${profile_host}:${NODE_PRODUCT}/\${node_class}/linux/ /home/couchbase/ ; \
         done \
      && (if [ -d ~/.ssh ]; then chmod 00700 ~/.ssh; fi) \
      && (if [ -d ~/.gpg ]; then chmod 00700 ~/.gpg; fi)"

  # we could concievably be running the container as root or couchbase, let's try
  # to populate the profile data correctly either way
  if [ "${active_user}" = "couchbase" ]
  then
    sudo chmod 600 /run/secrets/profile_sync || :
    sudo chown couchbase:couchbase /run/secrets/profile_sync || :
    eval "$start_cmd" || exit 1
  else
    chmod 600 /run/secrets/profile_sync || :
    chown couchbase:couchbase /run/secrets/profile_sync || :
    su couchbase -c "$start_cmd" || exit 1
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
        key_name=$(gpg --list-packets "${gpgkey}" | grep ":user ID packet:" | sed "s/:user ID packet: //" | sed "s/\"//g")
        sudo -u couchbase -H gpg --list-keys | grep "${key_name}" &>/dev/null || (
          echo Importing ${gpgkey} ...
          sudo -u couchbase -H gpg --import ${gpgkey}
        )
    done
    shopt -u nullglob
}

# if first argument is "swarm", download and run the Jenkins swarm jar with any arguments
[[ "$1" == "swarm" ]] && {
    unset profiledata_key

    AGENT_MODE=${AGENT_MODE:-exclusive}
    jenkins_user=$(echo -n ${jenkins_user:-$(cat /run/secrets/jenkins_master_username)} | xargs)
    shift

    curl --fail -o /tmp/swarm-client.jar ${JENKINS_MASTER}/swarm/swarm-client.jar

    if [ ! -z "${JENKINS_TUNNEL}" ]; then
      TUNNEL_ARG="-tunnel ${JENKINS_TUNNEL}"
    fi

    # Save some information about the agent for the healthcheck script
    # or anything else that might want it
    AGENT_NAME="${JENKINS_SLAVE_NAME}-$(hostname)"
    echo "${AGENT_NAME}" | sudo tee /var/run/jenkins_agent_name
    echo "${JENKINS_MASTER}" | sudo tee /var/run/jenkins_master_url
    echo "${JENKINS_SLAVE_LABELS}" | sudo tee /var/run/jenkins_agent_labels

    # We don't want the child to immediately die when the container is
    # stopped, so intercept SIGTERM and then run the healthcheck to see
    # if it's OK to die
    keepalive() {
      echo "Agent ${AGENT_NAME} stop requested!"
      sudo touch /var/run/jenkins_agent_stop_requested
      /usr/sbin/healthcheck.sh
    }
    trap keepalive TERM


    # We can sometimes get here before the logfile has been created
    # which results in the tail failing and no logs being streamed
    # so we get around this by ensuring it's present before the tail
    sudo touch /var/log/swarm-client.log
    sudo chown couchbase:couchbase /var/log/swarm-client.log

    echo "Agent ${AGENT_NAME} starting up..."
    if $(sudo --help &>/dev/null && :)
    then
      sudo -u couchbase --set-home --preserve-env \
        env -u jenkins_user -u jenkins_password -u SUDO_UID -u SUDO_GID -u SUDO_USER -u SUDO_COMMAND \
        PATH=/usr/local/bin:/usr/bin:/bin \
        java $JAVA_OPTS \
        -jar /tmp/swarm-client.jar \
        -fsroot "${JENKINS_SLAVE_ROOT:-/home/couchbase/jenkins}" \
        -master "${JENKINS_MASTER}" \
        ${TUNNEL_ARG} \
        -mode ${AGENT_MODE} \
        -executors "${JENKINS_SLAVE_EXECUTORS:-1}" \
        -name "${AGENT_NAME}" \
        -disableClientsUniqueId \
        -deleteExistingClients \
        -labels "${JENKINS_SLAVE_LABELS} ${CONTAINER_TAG//\//_}" \
        -retry 5 \
        -noRetryAfterConnected \
        -username "${jenkins_user}" \
        -password @/run/secrets/jenkins_master_password \
        >& /var/log/swarm-client.log &
    else
      sudo -u couchbase -H \
        env -u jenkins_user -u jenkins_password -u SUDO_UID -u SUDO_GID -u SUDO_USER -u SUDO_COMMAND \
        PATH=/usr/local/bin:/usr/bin:/bin \
        java $JAVA_OPTS \
        -jar /tmp/swarm-client.jar \
        -fsroot "${JENKINS_SLAVE_ROOT:-/home/couchbase/jenkins}" \
        -master "${JENKINS_MASTER}" \
        ${TUNNEL_ARG} \
        -mode ${AGENT_MODE} \
        -executors "${JENKINS_SLAVE_EXECUTORS:-1}" \
        -name "${AGENT_NAME}" \
        -disableClientsUniqueId \
        -deleteExistingClients \
        -labels "${JENKINS_SLAVE_LABELS} ${CONTAINER_TAG//\//_}" \
        -retry 5 \
        -noRetryAfterConnected \
        -username "${jenkins_user}" \
        -password @/run/secrets/jenkins_master_password \
        >& /var/log/swarm-client.log &
    fi

    # Save PID of child for healthcheck/reaping
    PID=$!
    echo "${PID}" | sudo tee /var/run/jenkins_agent_pid

    # Send logs to stdout for "docker service logs"
    tail -f /var/log/swarm-client.log &

    # Also, we no longer want to exit THIS script on any error
    set +e

    # Loop forever, until the child process is actually gone
    while test -d /proc/${PID}; do
       wait $PID
    done
    echo "Agent ${AGENT_NAME} exiting"
    exit
}

# if first argument is "default", for backwards-compatibility start sshd
# (as new, long-running, foreground process)
[[ "$1" == "default" ]] && {
    mkdir -p /home/couchbase/jenkins
    chown -R couchbase:couchbase /home/couchbase/jenkins
    if ! ls /etc/ssh/ssh_host_* &>/dev/null
    then
      ssh-keygen -A
    fi

    # Ensure password auth disabled
    if grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config
    then
      sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config
    else
      echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
      echo >> /etc/ssh/sshd_config
    fi
    if grep -q "^[^#]*ChallengeResponseAuthentication" /etc/ssh/sshd_config
    then
      sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config
    else
      echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config
      echo >> /etc/ssh/sshd_config
    fi

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

  if $(sudo --help &>/dev/null && :)
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
