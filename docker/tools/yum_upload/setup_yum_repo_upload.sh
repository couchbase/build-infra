#!/bin/bash

mkdir -p /home/couchbase/.aws /home/couchbase/.ssh

# Copy needed GPG and AWS credential files from /ssh into .ssh and .aws,
# ensure ownership and permissions are correct
if [[ -d /ssh ]] && [[ "$(ls -A /ssh)" ]]
then
    cp -a /ssh/*.gpg /home/couchbase/.ssh
    cp -a /ssh/GPG-KEY-COUCHBASE-1.0 /home/couchbase/.ssh
    cp -a /ssh/aws-credentials /home/couchbase/.aws/credentials
fi
chown -R couchbase:couchbase /home/couchbase/.aws /home/couchbase/.ssh
chmod 600 /home/couchbase/.aws/* /home/couchbase/.ssh/*

# Run repo_upload program with 'yum' option
[[ "$1" == "default" ]] && {
    exec /usr/bin/repo_upload -c /etc/repo_upload.ini -r yum -e $EDITION
}

exec "$@"
