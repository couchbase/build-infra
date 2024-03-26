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
	GO="${HOME}/go/bin/go"

	if [ ! -x ${GO} ]; then
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

# Clean up installed binaries, and recursively inspect dependencies.
run_go "clean -i -r"

# Clean up old docker images.
run "docker system prune --filter 'until=6h' --force"

# Run a local Bazel clean.
run_bazel "clean"

# If we're under a given threshold, let CV continue before going nuclear and deleting everything.
if [[ $(usage) -lt 75 ]]; then
	exit 0
fi

# Completely remove the Go build cache.
run "rm -rf ${HOME}/.cache/go-build"

# Completely remove any Go caches.
run_go "clean -i -r -cache -testcache -modcache -fuzzcache"

# Prune everything possible from Docker.
run "docker system prune --all --volumes --force"

# Remove the Bazel cache, working tree and output files.
run_bazel "clean --expunge"
