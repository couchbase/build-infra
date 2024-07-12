#!/usr/bin/env bash

set -e
current_log=$(find /opt/gha/_diag -type f -name 'Runner*.log' -exec stat --format='%Y %n' {} + | sort -n | tail -1 | cut -d' ' -f2-)
job_end_lines="Get messages has been cancelled using local token source|Set runner/worker IPC timeout to 30 seconds|Job completed|No message retrieved from session|Job completed|Runner execution been cancelled"
gha_service=$(systemctl list-units --all --type=service --no-pager --no-legend "actions.runner*" | awk '{print $1}')

echo "Monitoring latest logfile for end of job: $current_log"

terminate_runner() {
    echo "$(date) Terminating runner"
    sudo systemctl stop "${gha_service}"
}

if [ ! -f "${current_log}" ]; then
    terminate_runner
elif ! lsof | grep -q "$current_log"; then
    terminate_runner
elif tail -n1 "$current_log" | grep --line-buffered -E "$job_end_lines"; then
    terminate_runner
else
    tail -f -n1 $current_log | while read LINE
    do
        echo "$LINE" | grep --line-buffered -E "$job_end_lines" \
            && echo "$(date) no jobs running, terminating runner" \
            && terminate_runner \
            && break
    done
fi
