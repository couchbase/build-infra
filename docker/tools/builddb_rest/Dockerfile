# Docker container for build database REST API on Ubuntu 16.04
#
# Contains the following:
#  - cbbuild package from python-couchbase-commons
#  - builddb_rest code

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Checkout directory for build-infra repository
ARG BUILD_INFRA_GITDIR=/var/tmp/build-infra

# Clone repository, install software in build_database directory,
# then delete repository
RUN git clone https://github.com/couchbase/build-infra $BUILD_INFRA_GITDIR && \
    cd $BUILD_INFRA_GITDIR/builddb_rest && \
    git log -1 && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $BUILD_INFRA_GITDIR

CMD ["pserve", "/etc/builddb_rest.ini"]
