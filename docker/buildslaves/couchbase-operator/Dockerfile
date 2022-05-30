# Jenkins buildslave container for building couchbase-operator

# We'll inherit from the Couchbase Server build slave just to
# avoid re-inventing the wheel and for Docker image cache sharing

FROM couchbasebuild/server-ubuntu20-build:20220527
LABEL maintainer=build-team@couchbase.com

COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# Docker; xmllint (used for parsing manifest); jq (used for parsing
# output from builddb REST API)
RUN set -x \
    && apt-get update \
    && apt-get install -y apt-transport-https \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli libxml2-utils jq \
    && apt-get clean

RUN addgroup --gid 999 docker && \
    usermod -a -G docker couchbase

RUN set -x \
    && mkdir -p /home/couchbase/.docker \
    && chown couchbase:couchbase /home/couchbase/.docker

# Set up buildx driver
RUN docker buildx create --use

# cbdep (used to install Go)
ARG CACHEBUST=1
RUN curl --fail https://packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

COPY build/couchbuilder_start.sh /usr/sbin/

COPY build/swarm*.properties /
