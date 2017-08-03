#!/bin/bash
#
# Primitive restart script for Hari's buildboard containers.
#
# The '-d' option is for restarting the database as well (should rarely
# be needed).  Simply restarts all the containers with short pauses
# between each restart, exiting with a return code of 1 if any of the
# restarts fail.

while getopts ":d" opt; do
    case $opt in
        d)
            RESTART_DB=true
            ;;
        \?)
            echo "Usage: $0 [-d]" >&2
            exit 1
            ;;
    esac
done

if [[ "${RESTART_DB}" == "true" ]]; then
    echo "Restarting DB"
    /usr/bin/docker restart temp-bbdb-database || exit 1
    sleep 20   # Give DB a bit of time to restart
fi

echo "Restarting DB loader"
/usr/bin/docker restart temp-bbdb-loader || exit 1
/bin/sleep 5

echo "Restarting REST API interface"
/usr/bin/docker restart temp-restapis || exit 1
/bin/sleep 5

echo "Restarting changelog interface"
/usr/bin/docker restart temp-changelog || exit 1
/bin/sleep 5

exit 0
