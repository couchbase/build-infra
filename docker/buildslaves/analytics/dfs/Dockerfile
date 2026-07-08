# Analytics docker container based on linux-dfs

FROM couchbasebuild/server-builder:20260421
LABEL maintainer="build-team@couchbase.com"

USER root

# Install docker static binary for running docker command-line
RUN set -x \
  && mkdir /tmp/deploy \
  && cd /tmp/deploy \
  && curl -o docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-23.0.6.tgz \
  && tar xf docker.tgz \
  && cp -a docker/docker /usr/local/bin \
  && cd /tmp \
  && rm -rf deploy

USER couchbase
WORKDIR /home/couchbase

# Enable .gitconfig so repo doesn't get whiny
COPY --chown=couchbase:couchbase gitconfig /home/couchbase/.gitconfig

# ENV vars for profile data retrieval
ENV NODE_CLASS=cv
ENV NODE_PRODUCT=couchbase-server

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
