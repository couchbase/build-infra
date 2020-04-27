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

if [ -f /run/secrets/profile_sync -a ! -e "${NODE_CLASS}" -a ! -e "${NODE_PRODUCT}" ]
then
  echo "###########################"
  echo "# Populating profile data #"
  echo "###########################"

  chmod 600 /run/secrets/profile_sync

  # Ensure the host where the profile data lives is in our known_hosts before synchronisation. We also
  # have to set permissions on directories here as we can only specify perms on files in the profile container
  start_cmd="mkdir ~/.ssh \
    && add_hostkeys \
    && rsync --progress --archive --backup --executability --no-o --no-g -e \"ssh -p ${profile_port} -i /run/secrets/profile_sync\" couchbase@${profile_host}:${NODE_PRODUCT}/${NODE_CLASS}/linux/ /home/couchbase/ \
    && ([ -d ~/.ssh ] && chmod 00700 ~/.ssh) \
    && ([ -d ~/.gpg ] && chmod 00700 ~/.gpg)"

  # we could concievably be running the container as root or couchbase, let's try
  # to populate the profile data correctly either way
  if [ "$(whoami)" = "couchbase" ]
  then
    eval $start_cmd
  else
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
