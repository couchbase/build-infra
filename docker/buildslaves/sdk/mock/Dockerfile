# Docker container for Centos8

FROM couchbasebuild/sdk-ubi8-build:20221017
LABEL maintainer="build-team@couchbase.com"

USER root

RUN yum install -y --enablerepo centos8-appstream,centos8-baseos mock && yum clean all
RUN usermod -a -G mock couchbase

USER couchbase

# Need to repeat this to override settings from base image
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
