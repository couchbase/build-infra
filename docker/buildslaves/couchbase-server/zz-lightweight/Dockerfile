# Docker container for Ubuntu 16.04

FROM couchbasebuild/server-ubuntu16-build:20200211
LABEL maintainer="build-team@couchbase.com"

COPY build/cb-buildbot-config.sh /usr/sbin/couchhook.d/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
