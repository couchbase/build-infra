# Docker container for Ubuntu 12.04 CV
# This is a slightly hacky work-around to fix the problem of installing
# JDK 8 on an Ubuntu 12 slave. That slave's original docker image hasn't
# been rebuilt in 2.5 years, so it very likely would either fail to build
# or would build something unexpected. There isn't a package for JDK 8 in
# Ubuntu 12 anyway. So we simply extend the existing image here, dropping
# our local JDK into it.

FROM ceejatec/ubuntu-1204-couchbase-cv:20160304
MAINTAINER build-team@couchbase.com

USER root

COPY build/jdk1.8.0_181 /usr/local
RUN for bin in /usr/local/jdk1.8.0_181/bin/*; do ln -s $bin /usr/local/bin; done
ENV JAVA_HOME=/usr/local/jdk1.8.0_181

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" > /home/couchbase/.ssh/environment
RUN chown couchbase:couchbase /home/couchbase/.ssh/environment
