# Jenkins buildslave container for building couchbase-operator

# We'll inherit from the Couchbase Server build slave just to
# avoid re-inventing the wheel and for Docker image cache sharing

FROM couchbasebuild/server-ubuntu16-build:20190507
MAINTAINER Couchbase Build Team <build-team@couchbase.com>

# Docker
RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    apt-get clean

RUN addgroup --gid 999 docker && \
    usermod -a -G docker couchbase

# Go
ARG GOVERSION=1.13.3
RUN mkdir -p /usr/local/go/${GOVERSION} && cd /usr/local/go/${GOVERSION} && \
    curl https://storage.googleapis.com/golang/go${GOVERSION}.linux-amd64.tar.gz -o go.tar.gz && \
    tar xf go.tar.gz && \
    rm go.tar.gz && \
    ln -s /usr/local/go/${GOVERSION}/go/bin/go /usr/local/bin

# Dep
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl https://raw.githubusercontent.com/golang/dep/master/install.sh -o install-dep.sh && \
    INSTALL_DIRECTORY=/usr/local/bin bash install-dep.sh && \
    cd /tmp && \
    rm -rf deploy

# Local hook (necessary for Docker configuration)
COPY couchhook.sh /usr/sbin
