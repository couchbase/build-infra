#!/bin/bash -ex

docker run --pull always --rm -u couchbase \
    -v /buildteam:/buildteam \
    -v /home/couchbase/jenkinsdocker-ssh:/home/couchbase/.ssh \
    -v /home/couchbase/build_database/build_db_loader_conf.ini:/etc/build_db_loader_conf.ini \
    -v /home/couchbase/build_database:/home/couchbase/build_database \
    couchbasebuild/load-build-database:latest \
    load_build_database -c /etc/build_db_loader_conf.ini -d

docker run --rm -u couchbase \
    -v /buildteam:/buildteam \
    -v /home/couchbase/build_database/build_db_loader_conf.ini:/etc/build_db_loader_conf.ini \
    -v /home/couchbase/build_database/jira-creds.json:/home/couchbase/jira-creds.json \
    -v /home/couchbase/build_database/cloud-jira-creds.json:/home/couchbase/cloud-jira-creds.json \
    couchbasebuild/load-build-database:latest \
    jira_commenter -d \
        -c /etc/build_db_loader_conf.ini \
        --issues-creds /home/couchbase/jira-creds.json \
        --cloud-creds /home/couchbase/cloud-jira-creds.json
