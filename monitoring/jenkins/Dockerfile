# Docker container for Jenkins monitoring on Ubuntu 16.04
#
# Contains the following:
#  - jenkins code

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Checkout directory for build-infra repository
ARG SRCDIR=/var/tmp/build-infra

COPY . $SRCDIR

# Clone repository, install software in jenkins directory,
# then delete repository
RUN cd $SRCDIR && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $SRCDIR

CMD ["monitor_jenkins", "-c", "/etc/jenkins_monitor.json"]
