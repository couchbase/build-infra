# This Dockerfile exists only to update cbdep etc. We can no longer build
# the original Docker image as at least the ICU binary we depended on has
# been removed from the internet. The file Dockerfile.historic is the
# Dockerfile that the image was originally build from.

FROM couchbasebuild/sdk-centos6-build:20191204

# Temp install step for "cbdep" tool
ARG CACHEBUST=1
USER root
RUN curl http://downloads.build.couchbase.com/cbdep/cbdep.linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep
USER couchbase

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
