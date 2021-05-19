#!/bin/bash

# Necessary for old-skool jenkinsdocker-ssh mount; not needed when
# using profiledata
if [ -d /ssh ]; then
    cp -a /ssh/config-cb-buildbot /home/couchbase/.ssh/config
    chown couchbase:couchbase /home/couchbase/.ssh/config
    chmod 600 /home/couchbase/.ssh/config
fi
