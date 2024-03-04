#!/bin/bash

## during golang upgrade, multiple version of golang's modules are
## cached in .cache/go-build.  Diskspace fills up quickly.  We need
## remove the directory to free up the diskspace.
used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge 85 ]]; then
  echo -e "$(date) \tDisk usage is above 85% - removing go-build cache"
  rm -rf /home/couchbase/.cache/go-build
fi

# If things are still bad, run docker system prune
used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge 85 ]]; then
  echo -e "$(date) \tDisk usage is above 85% - running docker system prune"
  docker system prune --force
fi

# Still bad, run docker system prune --all to clear build cache
used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge 85 ]]; then
  echo -e "$(date) \tDisk usage is above 85% - running docker system prune --all"
  docker system prune --all --volumes --force
fi

# Still bad, the hammer: bazel clean --expunge
used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge 85 ]]; then
  if [ -d /opt/gha/_work/couchbase-cloud/couchbase-cloud ]; then
    echo -e "$(date) \tDisk usage is above 85% - running bazel clean --expunge"
    cd /opt/gha/_work/couchbase-cloud/couchbase-cloud
    /home/couchbase/go/bin/bazel clean --expunge
    mkdir -p $(/home/couchbase/go/bin/bazel info output_path)
  fi
fi
