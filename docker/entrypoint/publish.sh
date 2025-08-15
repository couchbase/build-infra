#!/bin/bash -ex

aws s3 sync --acl public-read plugins s3://cb-entry/plugins --delete
aws s3 sync --acl public-read healthchecks s3://cb-entry/healthchecks --delete
aws s3 cp --acl public-read universal-entrypoint.sh s3://cb-entry/universal-entrypoint.sh
