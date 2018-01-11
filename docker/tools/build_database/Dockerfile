# Docker container load_build_database program on Ubuntu 16.04
#
# Contains the following:
#  - cbbuild package from python-couchbase-commons
#  - build_database programs (just load_build_database currently)

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Checkout directory for build-infra repository
ARG BUILD_INFRA_GITDIR=/var/tmp/build-infra

# Clone repository, install software in build_database directory,
# then delete repository
RUN git clone https://github.com/couchbase/build-infra $BUILD_INFRA_GITDIR && \
    cd $BUILD_INFRA_GITDIR/build_database && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $BUILD_INFRA_GITDIR

CMD ["load_build_database", "-c", "/etc/build_db_loader_conf.ini"]
