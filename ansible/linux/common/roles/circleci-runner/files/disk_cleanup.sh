#/bin/bash

## during golang upgrade, multiple version of golang's modules are
## cached in .cache/go-build.  Diskspace fills up quickly.  We need
## remove the directory to free up the diskspace.

used_percent=$(df -kh . | tail -n1 | awk '{print $5}' |sed -e 's/%//')
if [[ $(($used_percent)) -ge 90 ]]; then
        echo -e "$(date) \tDisk usage is above 90%"
        rm -rf /home/couchbase/.cache/go-build
fi
