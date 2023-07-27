# Docker container for Centos8

FROM couchbasebuild/sdk-almalinux8-build:20230726
LABEL maintainer="build-team@couchbase.com"

USER root

RUN yum install -y mock && yum clean all
RUN usermod -a -G mock couchbase

USER couchbase

# Need to repeat this to override settings from base image
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
