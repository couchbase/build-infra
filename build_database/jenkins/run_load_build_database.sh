#!/bin/bash -ex

docker pull couchbasebuild/load-build-database
docker run --rm -u couchbase \
    -v /buildteam:/buildteam \
    -v /home/couchbase/jenkinsdocker-ssh:/home/couchbase/.ssh \
    -v /home/couchbase/build_database/build_db_loader_conf.ini:/etc/build_db_loader_conf.ini \
    -v /home/couchbase/build_database:/home/couchbase/build_database \
    couchbasebuild/load-build-database:20211001

docker run --rm -u couchbase \
    -v /buildteam:/buildteam \
    -v /home/couchbase/build_database/build_db_loader_conf.ini:/etc/build_db_loader_conf.ini \
    -v /home/couchbase/build_database/jira.netrc:/home/couchbase/.netrc \
    couchbasebuild/load-build-database:20211001 \
    jira_commenter -c /etc/build_db_loader_conf.ini -d
