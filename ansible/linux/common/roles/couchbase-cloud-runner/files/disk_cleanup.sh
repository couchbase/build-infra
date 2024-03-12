#!/bin/bash

# Disk free threshold - above 85%, try cleaning things
DF_THRESHOLD=85

# If disk free percentage is too low, try docker prune
used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge ${DF_THRESHOLD} ]]; then
  echo -e "$(date) \tDisk usage is above ${DF_THRESHOLD}% - running docker system prune"
  docker system prune --force
fi

# Still bad, run docker system prune --all to clear build cache
used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge ${DF_THRESHOLD} ]]; then
  echo -e "$(date) \tDisk usage is above ${DF_THRESHOLD}% - running docker system prune --all"
  docker system prune --all --volumes --force
fi

# Still bad, the hammer: bazel clean --expunge
used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge ${DF_THRESHOLD} ]]; then
  if [ -d /opt/gha/_work/couchbase-cloud/couchbase-cloud ]; then
    echo -e "$(date) \tDisk usage is above ${DF_THRESHOLD}% - running bazel clean --expunge"
    cd /opt/gha/_work/couchbase-cloud/couchbase-cloud
    /home/couchbase/go/bin/bazel clean --expunge
    mkdir -p $(/home/couchbase/go/bin/bazel info output_path)
  fi
fi
