#!/bin/bash

# If this is a "large" machine, enable larger ccache
if [[ "${JENKINS_SLAVE_LABELS}" == *"large"* ]]; then
    su couchbase -c "ccache --max-size=50G"
fi
