# Docker container for generate closed source

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

COPY requirements.txt /tmp
WORKDIR /tmp
RUN pip3.6 install -r requirements.txt

# Checkout directories for build-tools and manifest repositories
ARG BUILD_TOOLS_GITDIR=/home/couchbase/build-tools
ARG MANIFEST_GITDIR=/home/couchbase/manifest

RUN git clone https://github.com/couchbase/build-tools.git $BUILD_TOOLS_GITDIR && \
    git clone https://github.com/couchbase/manifest.git $MANIFEST_GITDIR

COPY gen-private-repo.sh /gen-private-repo.sh
CMD ["/gen-private-repo.sh"]
