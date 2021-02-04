# Docker container for Ubuntu 16.04

FROM couchbasebuild/server-ubuntu16-build:20201210
LABEL maintainer="build-team@couchbase.com"

# Install python3-apt
RUN set -x \
        && apt-get update \
        && apt-get install python3-apt \
        && apt-get clean \
        && cp /usr/lib/python3/dist-packages/apt_pkg.cpython-35m-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/apt_pkg.so

#install latest git
RUN add-apt-repository ppa:git-core/ppa -y && \
    apt-get update && \
    apt-get install -y git

#install rvm so that we can use it to upgrade ruby when necessary
RUN groupadd rvm && \
    sudo apt-add-repository -y ppa:rael-gc/rvm && \
    sudo apt-get update && \
    sudo apt-get install -y rvm

# Install Deno for running javascript
RUN set -x \
        && cd /usr/local/bin \
        && curl --fail -Lo deno.zip https://github.com/denoland/deno/releases/download/v1.7.1/deno-x86_64-unknown-linux-gnu.zip \
        && unzip deno.zip \
        && rm deno.zip

COPY build/cb-buildbot-config.sh /usr/sbin/couchhook.d/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]

# Avoid having to rebuild image chain for simple start script modifications
COPY build/couchbuilder_start.sh /usr/sbin/

# Hack because build-from-manifest script (and possibly others) hardcodes
# python3.6
RUN ln -s python3.7 /usr/bin/python3.6

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
