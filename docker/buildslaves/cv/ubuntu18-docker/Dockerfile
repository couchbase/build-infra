# Docker-enabled container for CV

FROM couchbasebuild/server-ubuntu18-build:20210405
LABEL maintainer="build-team@couchbase.com"

ARG DOCKER_VERSION

# ENV vars for profile data retrieval
ENV NODE_CLASS=cv
ENV NODE_PRODUCT=couchbase-server

USER root

WORKDIR /tmp

# Needed to ensure LANG is set correctly when ssh'ing into agent
COPY ssh_environment /home/couchbase/.ssh/environment
RUN set -x \
        && sed -ri 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config \
        && chown -R couchbase:couchbase /home/couchbase/.ssh

# Install patch_via_gerrit tool
RUN set -x \
        && curl -L https://packages.couchbase.com/patch_via_gerrit/1.0.0/patch_via_gerrit-1.0.0-linux -o /usr/local/bin/patch_via_gerrit \
        && chmod 755 /usr/local/bin/patch_via_gerrit

# Enable .gitconfig so repo doesn't get whiny
COPY gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Install docker static binary for running docker command-line
RUN set -x \
  && mkdir /tmp/deploy \
  && cd /tmp/deploy \
  && curl -o docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && tar xf docker.tgz \
  && cp -a docker/docker /usr/local/bin \
  && cd /tmp \
  && rm -rf deploy

# Add couchbase user to "docker" group on host (999)
# Also include GID 996 for ECS
RUN groupadd -g 999 docker && usermod -a -G docker couchbase
RUN groupadd -g 996 dockerecs && usermod -a -G dockerecs couchbase

# Enable disk-checking healthcheck
COPY healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Avoid having to rebuild image chain for simple start script modifications
COPY ./couchbuilder_start.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" >> /home/couchbase/.ssh/environment
