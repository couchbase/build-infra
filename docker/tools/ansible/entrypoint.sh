#!/bin/bash

# Script intended to be ENTRYPOINT

# First, copy any files in /ssh to $HOME/.ssh
if [ -d /ssh ] && [ "$(ls -A /ssh)" ]
then
    mkdir $HOME/.ssh
    cp -a /ssh/* $HOME/.ssh
    chmod 600 $HOME/.ssh/*
fi

# Ensure /mnt is PWD, if available
if [ -d /mnt ]
then
    cd /mnt
fi

export ANSIBLE_HOST_KEY_CHECKING=false

exec ansible-playbook "$@"

