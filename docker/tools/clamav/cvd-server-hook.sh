#!/bin/bash

# Update to get the initial database
cvd config set --dbdir /var/clamav/database
echo "Running cvd update to get initial Clamav database, please wait"
cvd update

# Run the mirror server
nohup cvd serve >& /tmp/cvd-serve.log &
