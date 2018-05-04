FROM ceejatec/ubuntu-1604-couchbase-build:latest
MAINTAINER build-team@couchbase.com

RUN apt-get update && \
    apt-get install -y clamav-daemon rpm2cpio cpio && \
    apt-get clean

COPY couchhook.sh /usr/sbin/
