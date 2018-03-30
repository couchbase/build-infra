#!/bin/bash -e

mkdir -p /home/couchbase/.aws /home/couchbase/.ssh

# Copy needed GPG and AWS credential files from /ssh into .ssh and .aws,
# ensure ownership and permissions are correct
if [[ ! -d /ssh ]] || [[ ! "$(ls -A /ssh)" ]]
then
    echo "Missing key configuration files in /ssh"
    exit 1
else
    cp -a /ssh/*.gpg /home/couchbase/.ssh
    cp -a /ssh/GPG-KEY-COUCHBASE-1.0 /home/couchbase/.ssh
    cp -a /ssh/aws-credentials /home/couchbase/.aws/credentials
fi

chown -R couchbase:couchbase /home/couchbase/.aws /home/couchbase/.ssh
chmod 600 /home/couchbase/.aws/* /home/couchbase/.ssh/*

[[ "$1" == "debug" ]] && {
    shift
    exec "$@"
}

# Run repo_upload program with 'apt' option
cd /home/couchbase
exec /usr/local/bin/repo_upload -c /etc/repo_upload.ini -r apt "$@"
