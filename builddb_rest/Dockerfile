# Docker container for build database REST API on Ubuntu 16.04
#
# Contains the following:
#  - cbbuild package from python-couchbase-commons
#  - builddb_rest code

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Checkout directory for build-infra repository
ARG SRCDIR=/var/tmp/build-infra

COPY . $SRCDIR

# Clone repository, install software in build_database directory,
# then delete repository
RUN cd $SRCDIR && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $SRCDIR

COPY scripts/builddb_rest_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/builddb_rest_start.sh" ]
CMD [ "default" ]
