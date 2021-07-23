# Docker container for SUSE 15, based on openSUSE LEAP

FROM couchbasebuild/server-suse15-build:20200424
LABEL maintainer="build-team@couchbase.com"

# Ensure disk-checking healthcheck up to date
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Copy startup script
COPY build/couchbuilder_start.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
