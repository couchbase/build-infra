# Docker container for Centos7

FROM couchbasebuild/sdk-centos7-build:20181002
MAINTAINER build-team@couchbase.com

RUN sudo yum install --setopt=keepcache=0 -y mock
RUN sudo usermod -a -G mock couchbase

# Need to repeat this to override settings from base image
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
