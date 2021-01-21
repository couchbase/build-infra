#!/usr/bin/env bash

set -e

if [ "$1" != "" ]; then
    exec "$@"
else
    if [ "$SOURCE_URL" != "" ]
    then
        echo "Downloading source tarball..."
        curl --fail --silent "$SOURCE_URL" | tar -xz
    else
        echo "Starting repo sync..."
        export MANIFEST_URL=${MANIFEST_URL:-git://github.com/couchbase/manifest}
        export MANIFEST_BRANCH=${MANIFEST_BRANCH:-master}
        export MANIFEST_FILE=${MANIFEST_FILE:-branch-master.xml}
        export MANIFEST_GROUPS=${MANIFEST_GROUPS:-all}
        set -x && repo init -u "${MANIFEST_URL}" -b "${MANIFEST_BRANCH}" -m "${MANIFEST_FILE}" -g "${MANIFEST_GROUPS}"
        set +x
        repo sync -j8
        echo
    fi

    if [ "$1" = "" ]; then
        exec find-patterns
    fi
fi
