# Jenkins buildslave container for building couchbase-operator

FROM couchbasebuild/server-linux-build:20260109 AS skopeo
ENV GOPATH=/tmp/gopath
ENV PATH=/usr/local/go/bin:$PATH
RUN set -x \
  && yum install -y btrfs-progs-devel device-mapper-devel make \
  && curl -Lf https://go.dev/dl/go1.24.4.linux-amd64.tar.gz > /tmp/go.tar.gz \
  && tar -C /usr/local -xzf /tmp/go.tar.gz \
  && git clone https://github.com/containers/skopeo $GOPATH/src/github.com/containers/skopeo \
  && cd $GOPATH/src/github.com/containers/skopeo && make bin/skopeo BUILDTAGS=containers_image_openpgp

# We'll inherit from the Couchbase Server build slave just to
# avoid re-inventing the wheel and for Docker image cache sharing

FROM couchbasebuild/server-linux-build:20260109
LABEL maintainer=build-team@couchbase.com

COPY --from=skopeo /tmp/gopath/src/github.com/containers/skopeo/bin/skopeo /usr/local/bin/skopeo
COPY --from=skopeo /tmp/gopath/src/github.com/containers/skopeo/default-policy.json /etc/containers/policy.json
COPY --from=docker/buildx-bin:0.27.0 /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# xmllint (used for parsing manifest); jq (used for parsing
# output from builddb REST API)
RUN set -x \
    && yum install -y libxml2 jq \
    && yum clean all

# Build and install bash 5+ from source
RUN set -x \
    && curl -Lf https://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz -o /tmp/bash.tar.gz \
    && tar -C /tmp -xzf /tmp/bash.tar.gz \
    && cd /tmp/bash-5.2 \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && ln -sf /usr/local/bin/bash /bin/bash \
    && rm -rf /tmp/bash-5.2 /tmp/bash.tar.gz

RUN set -x \
    && mkdir -p /home/couchbase/.docker \
    && chown couchbase:couchbase /home/couchbase/.docker

# AWS CLI v2
RUN set -x \
      && yum remove -y awscli \
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
