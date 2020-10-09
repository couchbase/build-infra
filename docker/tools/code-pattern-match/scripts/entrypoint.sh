#!/usr/bin/env bash

export MANIFEST_URL=${MANIFEST_URL:-git://github.com/couchbase/manifest}
export MANIFEST_FILE=${MANIFEST_FILE:-branch-master.xml}
export MANIFEST_GROUPS=${MANIFEST_GROUPS:-all}

set -e

if [ "$1" != "" ]; then
    exec "$@"
else
    set -x && repo init -u "${MANIFEST_URL}" -m "${MANIFEST_FILE}" -g "${MANIFEST_GROUPS}"
    set +x
    repo sync -j8
    echo

    if [ "$1" = "" ]; then
        exec find-patterns
    fi
fi
