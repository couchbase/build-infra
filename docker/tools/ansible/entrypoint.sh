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
