#!/bin/bash
#
# Primitive restart script for Hari's buildboard containers.
#
# The '-d' option is for restarting the database as well (should rarely
# be needed).  Simply restarts all the containers with short pauses
# between each restart, exiting with a return code of 1 if any of the
# restarts fail.

LOG=/tmp/hari_buildboard_restart.log

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

echo $(/bin/date) >> ${LOG}
echo "Starting container restart" >> ${LOG}

if [[ "${RESTART_DB}" == "true" ]]; then
    echo "Restarting DB" >> ${LOG}
    /usr/bin/docker restart temp-bbdb-database
    sleep 20   # Give DB a bit of time to restart
fi

echo "Restarting DB loader" >> ${LOG}
/usr/bin/docker restart temp-bbdb-loader
/bin/sleep 5

echo "Restarting REST API interface" >> ${LOG}
/usr/bin/docker restart temp-restapis
/bin/sleep 5

echo "Restarting changelog interface" >> ${LOG}
/usr/bin/docker restart temp-changelog
/bin/sleep 5

echo "----------" >> ${LOG}
(/usr/bin/docker ps | grep temp) >> ${LOG}
echo "" >> ${LOG}
echo "Finished container restart" >> ${LOG}
echo "==========" >> ${LOG}
exit 0
