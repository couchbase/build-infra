# Docker container for analytics.jenkins agent

FROM couchbasebuild/server-linux-build:20260109
LABEL maintainer="build-team@couchbase.com"

# ENV vars for profile data retrieval - analytics is basically CV
ENV NODE_CLASS=cv
ENV NODE_PRODUCT=couchbase-server

USER root

WORKDIR /tmp

# Install patch_via_gerrit tool
RUN set -x \
        && curl -L https://packages.couchbase.com/patch_via_gerrit/1.1.1/patch_via_gerrit-1.1.1-linux -o /usr/local/bin/patch_via_gerrit \
        && chmod 755 /usr/local/bin/patch_via_gerrit

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Enable .gitconfig so repo doesn't get whiny
COPY gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Install docker static binary for running docker command-line
RUN set -x \
  && mkdir /tmp/deploy \
  && cd /tmp/deploy \
  && curl -o docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-23.0.6.tgz \
  && tar xf docker.tgz \
  && cp -a docker/docker /usr/local/bin \
  && cd /tmp \
  && rm -rf deploy

# Add hook for setting jenkins/workspace permissions
COPY workspace-hook.sh /usr/sbin/couchhook.d/
# Enable additional hook for ccache
COPY ccache-hook.sh /usr/sbin/couchhook.d/

# Copy over the latest startup script
COPY build/couchbuilder_start.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
