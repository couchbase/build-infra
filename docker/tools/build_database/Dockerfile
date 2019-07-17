# Docker container load_build_database program on Ubuntu 16.04
#
# Contains the following:
#  - cbbuild package from python-couchbase-commons
#  - build_database programs

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root

# Working directory for build_database code
ARG BUILD_DATABASE_DIR=/var/tmp/build_database

# Install software in build_database directory,
# then delete
COPY build/build_database ${BUILD_DATABASE_DIR}
RUN cd $BUILD_DATABASE_DIR && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $BUILD_DATABASE_DIR

CMD ["load_build_database", "-c", "/etc/build_db_loader_conf.ini"]
