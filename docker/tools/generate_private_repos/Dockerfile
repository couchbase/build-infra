# Docker container for generate closed source program on Ubuntu 16.04
#
# Contains the following:
#  - cbbuild-manifest package from python-couchbase-commons
#  - generate_private_repos code from build-tools

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Checkout directory for build-tools repository
ARG BUILD_TOOLS_GITDIR=/var/tmp/build-tools

# Clone repository, install software in generate_private_repos directory,
# then delete repository
RUN git clone https://github.com/couchbase/build-tools $BUILD_TOOLS_GITDIR && \
    cd $BUILD_TOOLS_GITDIR/generate_private_repos && \
    git log -1 && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $BUILD_TOOLS_GITDIR

COPY gen-private-repo.sh /usr/sbin/
CMD ["default"]
ENTRYPOINT [ "/usr/sbin/gen-private-repo.sh" ]
