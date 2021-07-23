# Docker container for Ubuntu 18.04

# This has to be first - define the GCC version to use and
# the image to pull it from
FROM couchbasebuild/server-ubuntu18-build:20200424

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.share

# Start script
COPY build/couchbuilder_start.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
