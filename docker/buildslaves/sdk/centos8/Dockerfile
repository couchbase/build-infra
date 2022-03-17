# This Dockerfile exists only to update cbdep etc. We can no longer build
# the original Docker image since centos8 is no longer supported. The file
# Dockerfile.historic is the Dockerfile that the image was originally build from.

FROM couchbasebuild/sdk-centos8-build:20211209

# CMake
USER root
# Temp install step for "cbdep" tool
ARG CACHEBUST=1
USER root
RUN curl https://s3.amazonaws.com/packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep
USER couchbase

COPY build/couchbuilder_start.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
