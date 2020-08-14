# Docker container for Ubuntu 16.04

FROM couchbasebuild/server-ubuntu16-build:20200211
LABEL maintainer="build-team@couchbase.com"

# Install python3-apt
RUN apt-get install python3-apt && \
    cp /usr/lib/python3/dist-packages/apt_pkg.cpython-35m-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/apt_pkg.so

#install latest git
RUN add-apt-repository ppa:git-core/ppa -y && \
    apt-get update && \
    apt-get install -y git

COPY build/cb-buildbot-config.sh /usr/sbin/couchhook.d/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
