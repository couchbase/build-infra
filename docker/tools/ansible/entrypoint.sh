#!/bin/bash

# Script intended to be ENTRYPOINT

# First, copy any files in /ssh to $HOME/.ssh
if [ -d /ssh ] && [ "$(ls -A /ssh)" ]
then
    mkdir $HOME/.ssh
    cp /ssh/* $HOME/.ssh
    chmod 600 $HOME/.ssh/*
fi

# Ensure /mnt is PWD, if available
if [ -d /mnt ]
then
    cd /mnt
fi

# If any dirs look like /role*, add them to Ansible role path
shopt -s nullglob
ROLEDIRS=$(echo /role*)
if [ ! -z "${ROLEDIRS}" ]; then
    export ANSIBLE_ROLES_PATH=${ANSIBLE_ROLES_PATH}:${ROLEDIRS// /:}
fi

export ANSIBLE_HOST_KEY_CHECKING=false

# Activate the pre-created venv
. /venv/bin/activate

# If there's a requirements.yml, assume it's for ansible-galaxy tools that
# we need to have

if [ -e requirements.yml ]; then
    echo "requirements.yml exists - loading with ansible-galaxy"
    ansible-galaxy install -r requirements.yml
fi

exec ${ANSIBLE_COMMAND} "$@"
