# Docker container for Centos8

FROM couchbasebuild/sdk-centos8-build:20211209
LABEL maintainer="build-team@couchbase.com"

USER root

# Not at all sure about this workaround
RUN rpm --rebuilddb || ( \
        rm -rf /var/lib/rpm && \
        mv /var/lib/rpmrebuild* /var/lib/rpm \
)

RUN yum clean all && \
    yum install --setopt=keepcache=0 -y mock
RUN usermod -a -G mock couchbase

USER couchbase

# Need to repeat this to override settings from base image
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
