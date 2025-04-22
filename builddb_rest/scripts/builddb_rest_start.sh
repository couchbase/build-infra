#!/usr/bin/env bash


# Start pserve (as new, long-running, foreground process)
[[ "$1" == "default" ]] && {
    # Ensure the builddb_rest.ini file is present
    if [ ! -f /etc/builddb_rest.ini ]; then
        echo "Error: /etc/builddb_rest.ini not found."
        exit 1
    fi

    # Ensure an up-to-date (unmodified) product-metadata checkout
    # is available
    cd /home/couchbase
    rm -rf product-metadata
    git clone https://github.com/couchbase/product-metadata > /dev/null

    # Start the pserve server
    cd /home/couchbase/builddb_rest
    exec uv run pserve /etc/builddb_rest.ini
}

exec "$@"
