# Jenkins buildslave container for building couchbase-operator

FROM ubuntu:20.04 AS skopeo
ENV GOPATH=/tmp/gopath
ENV PATH=/usr/local/go/bin:$PATH
RUN set -x \
  && apt update \
  && DEBIAN_FRONTEND=noninteractive apt install -y curl gcc git libgpgme-dev libassuan-dev libbtrfs-dev libdevmapper-dev make pkg-config \
  && curl -Lf https://go.dev/dl/go1.24.4.linux-amd64.tar.gz > /tmp/go.tar.gz \
  && tar -C /usr/local -xzf /tmp/go.tar.gz \
  && git clone https://github.com/containers/skopeo $GOPATH/src/github.com/containers/skopeo \
  && cd $GOPATH/src/github.com/containers/skopeo && make bin/skopeo

# We'll inherit from the Couchbase Server build slave just to
# avoid re-inventing the wheel and for Docker image cache sharing

FROM couchbasebuild/server-ubuntu20-build:20220527
LABEL maintainer=build-team@couchbase.com

COPY --from=skopeo /tmp/gopath/src/github.com/containers/skopeo/bin/skopeo /usr/local/bin/skopeo
COPY --from=skopeo /tmp/gopath/src/github.com/containers/skopeo/default-policy.json /etc/containers/policy.json
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# Install latest git
RUN set -x \
    && apt-get update \
    && apt-get install -y \
       software-properties-common \
    && LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/x86_64-linux-gnu add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y git \
    && apt-get clean

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

# AWS CLI
RUN set -x \
      && mkdir /tmp/deploy \
      && cd /tmp/deploy \
      && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
      && unzip awscliv2.zip \
      && ./aws/install \
      && cd /tmp \
      && rm -rf deploy
ENV AWS_SHARED_CREDENTIALS_FILE=/home/couchbase/.aws/credentials

# cbdep (used to install Go)
ARG CACHEBUST=1
RUN curl --fail https://packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/buildx.sh /usr/sbin/couchhook.d/
COPY build/swarm*.properties /
