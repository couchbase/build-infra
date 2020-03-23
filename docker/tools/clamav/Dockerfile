FROM couchbasebuild/server-ubuntu18-build:latest

MAINTAINER build-team@couchbase.com

RUN apt-get update && \
    apt-get install -y clamav rpm2cpio cpio && \
    apt-get clean
