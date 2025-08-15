#!/bin/bash -e
#
# Universal Entrypoint Script for Couchbase Build Containers
# https://github.com/couchbase/build-infra/blob/master/docker/entrypoint

# Note: these CB_ variables are used by the entrypoint plugin also, so
# don't change the variable names.
export CB_ENTRYPOINT_BASE=${CB_ENTRYPOINT_BASE:-https://cb-entry.s3.us-west-2.amazonaws.com}
export CB_ENTRYPOINT_LOCAL_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export CB_ENTRYPOINT_PLUGIN_CACHE=/tmp/entrypoint-plugins

# Manually download and invoke the real entrypoint plugin.
rm -rf "${CB_ENTRYPOINT_PLUGIN_CACHE}"
mkdir -p "${CB_ENTRYPOINT_PLUGIN_CACHE}/universal"
plugpath=universal/entrypoint.sh

if [ ! -z "${CB_DEBUG_LOCAL_PLUGINS}" ]; then
    echo "Bootstrap from ${CB_ENTRYPOINT_LOCAL_ROOT}/plugins/${plugpath}"
    cp "${CB_ENTRYPOINT_LOCAL_ROOT}/plugins/${plugpath}" ${CB_ENTRYPOINT_PLUGIN_CACHE}/${plugpath}
else
    echo "-- Bootstrap from ${CB_ENTRYPOINT_BASE}/plugins/${plugpath}"
    curl -fsSL \
        "${CB_ENTRYPOINT_BASE}/plugins/${plugpath}" \
        > ${CB_ENTRYPOINT_PLUGIN_CACHE}/${plugpath}
fi
source ${CB_ENTRYPOINT_PLUGIN_CACHE}/${plugpath}
