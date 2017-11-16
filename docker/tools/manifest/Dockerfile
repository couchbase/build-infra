# Docker container recreate_build_manifest program on Ubuntu 16.04

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Checkout directory for build-tools repository
ARG BUILD_TOOLS_GITDIR=/var/tmp/build-tools

# Clone repository, install software in manifest-tools directory,
# then delete repository
RUN git clone https://github.com/couchbase/build-tools $BUILD_TOOLS_GITDIR && \
    cd $BUILD_TOOLS_GITDIR/manifest-tools && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $BUILD_TOOLS_GITDIR

CMD ['/usr/bin/recreate_build_manifest']
