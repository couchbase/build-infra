#!/bin/bash

# Create config dif
mkdir -p /var/clamav/database

# Set config dir
cvd config set --dbdir /var/clamav/database

# Start the mirror server
nohup cvd serve >& /tmp/cvd-serve.log &
