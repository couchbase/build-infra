# Docker container for system inventory program on Ubuntu 16.04
#
# Contains the following:
#  - cbbuild package from python-couchbase-commons
#  - infradb code

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Checkout directory for build-infra repository
ARG BUILD_INFRA_GITDIR=/var/tmp/build-infra

# Clone repository, install software in build_database directory,
# then delete repository
# NOTE: urllib3 1.22 is installed first due to a bug in the latest
#       requests version that doesn't handle version conflict right;
#       can be removed once requests is updated with the fix
RUN git clone https://github.com/couchbase/build-infra $BUILD_INFRA_GITDIR && \
    cd $BUILD_INFRA_GITDIR/infradb && \
    pip3.6 install urllib3==1.22 && \
    git log -1 && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $BUILD_INFRA_GITDIR

CMD ["update_system_info", "-c", "/etc/servers.yaml"]
