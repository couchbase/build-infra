# Jenkins buildslave container for building couchbase-operator

# We'll inherit from the Couchbase Server build slave just to
# avoid re-inventing the wheel and for Docker image cache sharing

FROM ceejatec/ubuntu-1604-couchbase-build:20171214
MAINTAINER Couchbase Build Team <build-team@couchbase.com>

# Docker
RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce && \
    apt-get clean && \
    usermod -a -G docker couchbase

# Go 1.9
RUN mkdir -p /usr/local/go/1.9 && cd /usr/local/go/1.9 && \
    curl https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz -o go.tar.gz && \
    tar xf go.tar.gz && \
    rm go.tar.gz && \
    ln -s /usr/local/go/1.9/go/bin/go /usr/local/bin

# Glide
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L https://github.com/Masterminds/glide/releases/download/v0.13.1/glide-v0.13.1-linux-amd64.tar.gz -o glide.tar.gz && \
    tar xf glide.tar.gz && \
    mv -i linux-amd64/glide /usr/local/bin && \
    cd /tmp && \
    rm -rf deploy
