#!/bin/bash

# NOTE: This script is launched by GitHub Actions at the start of each
# job, not cron. It is therefore guaranteed that no real build job is
# executing, so it's safe to do things like deleting caches.

# Log output of this script
LOGFILE=/home/couchbase/disk_cleanup.log
exec 3>&1 1>>${LOGFILE} 2>&1

# Disk free threshold check - above 80%, try cleaning things
disk_too_full() {
  used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
  [[ $(($used_percent)) -ge 80 ]]
}

# If disk free percentage is too low, try docker prune
if disk_too_full; then
  echo -e "$(date) \trunning docker system prune"
  docker system prune --force
fi

# Next up, blow away Go build cache
if disk_too_full; then
  echo -e "$(date) \tdeleting go-build cache"
  rm -rf ~/.cache/go-build
fi

# Still bad, run docker system prune --all --volumes to clear build cache
if disk_too_full; then
  echo -e "$(date) \trunning docker system prune --all --volumes --force"
  docker system prune --all --volumes --force
fi

# Finally, the hammer - bazel clean --expunge.
if disk_too_full; then
  # This would be created by GHA jobs at this path
  BZL=/home/couchbase/go/bin/bazel
  if [ -x ${BZL} ]; then
    echo -e "$(date) \trunning bazel clean --expunge"
    cd /opt/gha/_work/couchbase-cloud/couchbase-cloud

    # Shut down any currently-running Bazel server (shouldn't be any)
    ${BZL} shutdown

    # Run clean - this starts a new server but shuts it down afterwards
    ${BZL} clean --expunge

    # Start a new server to cause it to re-create the "external" directories
    ${BZL} info output_path

    # Shut it down again so that the first build job will create it fresh
    ${BZL} shutdown
  fi
fi

echo -e "$(date) \tDisk cleanup completed."
