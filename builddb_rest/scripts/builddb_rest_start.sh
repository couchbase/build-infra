#!/usr/bin/env bash

# Ensure an up-to-date (unmodified) product-metadata checkout
# is available
cd /home/couchbase
rm -rf product-metadata
git clone https://github.com/couchbase/product-metadata > /dev/null

# Start pserve (as new, long-running, foreground process)
[[ "$1" == "default" ]] && {
    exec /usr/local/bin/pserve /etc/builddb_rest.ini
}

exec "$@"
