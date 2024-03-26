#!/bin/bash -eu

set -o pipefail

# NOTE: This script is launched by GitHub Actions at the start of each
# job, not cron. It is therefore guaranteed that no real build job is
# executing, so it's safe to do things like deleting caches.

# Log to a file, so we have historical information.
LOGFILE="${HOME}/disk_cleanup.log"

# Returns the disk usage as a percentage (without the %).
function usage() {
  echo $(df -kh . | tail -n1 | awk '{print $5}' | sed -e 's/%//')
}

# Logs the given message to stdout and the logfile.
function log() {
  echo "$(date): $1" | tee -a ${LOGFILE}
}

# Runs the given command, displaying useful information before/after.
function run() {
  log "Started running \"$1\" | {\"usage\":\"$(usage)%\"}"

  eval $1

  log "Completed running \"$1\" | {\"usage\":\"$(usage)%\"}"
}

# Runs the given Go command, note that you do not need to provide the path to Go (e.g. clean -modcache).
function run_go() {
  # Find a usable install of Go, preferably the most up-to-date one.
  GO=$(find ${HOME}/install -name go -type f -executable | sort | tail -1)

  if [ ! -z ${GO} ]; then
    return
  fi

  run "${GO} $1"
}

# Runs the given Bazel command, note that you do not need to provide the path to Bazel (e.g. clean --expunge)
function run_bazel() {
  BAZEL="${HOME}/go/bin/bazel"

  if [ ! -x ${BAZEL} ]; then
    return
  fi

  run "${BAZEL} $1"
}

# Provide verbose information that will display the start/exit in GitHub Actions.
log "Disk cleanup starting"
trap "log 'Disk cleanup completed'" EXIT

# Go builds using '/tmp' by default and often litters these directories around.
run "rm -rf $(ls -d /tmp/go-build*)"

# Clean up old docker images.
run "docker system prune --filter 'until=6h' --force"

# A high watermark, percentage of disk space used.
THRESHOLD=75

# Sacrifice the test caches first; given the low churn, 'remote-cache' does a very good job of this.
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run_go "clean -testcache -fuzzcache"
fi

# Remove the module cache, which balloons with dependency upgrades.
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run_go "clean -modcache"
fi

# Finally, remove the build cache; that's the most useful to retain, if possible.
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run_go "clean -cache"
fi

# Perform a light Bazel clean, removing output and directories (but potentially leaving unknown targets).
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run_bazel "clean"
fi

# Completely remove any Go caches.
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run_go "clean -cache -testcache -modcache -fuzzcache"
fi

# If we were unable to find Go, delete some of the well known directories.
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run "rm -rf ${HOME}/.cache/go-build"
fi

# Prune everything possible from Docker.
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run "docker system prune --all --volumes --force"
fi

# Remove the Bazel cache, working tree and output files; this force Bazel's hand to clean-up everything.
if [[ $(usage) -gt ${THRESHOLD} ]]; then
  run_bazel "clean --expunge"
fi
