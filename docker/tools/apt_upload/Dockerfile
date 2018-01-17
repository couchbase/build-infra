# Docker container repo_upload program on Ubuntu 16.04
#
# Contains the repo_upload program for handling the APT uploads to S3

FROM couchbasebuild/ubuntu-1604-python3.6-base:latest
MAINTAINER build-team@couchbase.com

USER root
ENV EDITION enterprise

# Install Aptly
RUN apt-get update && \
    apt-get install -y wget && \
    echo "deb http://repo.aptly.info/ squeeze main" >> /etc/apt/sources.list && \
    wget -qO - https://www.aptly.info/pubkey.txt | apt-key add - && \
    apt-get update && \
    apt-get install -u aptly

# Checkout directory for build-tools repository
ARG BUILD_TOOLS_GITDIR=/var/tmp/build-tools

# Clone repository, install software in repo_upload directory,
# then delete repository
RUN git clone https://github.com/couchbase/build-tools $BUILD_TOOLS_GITDIR && \
    cd $BUILD_TOOLS_GITDIR/repo_upload && \
    pip3.6 install -r requirements.txt && \
    pip3.6 install . && \
    cd $HOME && \
    rm -rf $BUILD_TOOLS_GITDIR

COPY setup_apt_repo_upload.sh /usr/sbin/

ENTRYPOINT ["/usr/sbin/setup_apt_repo_upload.sh"]
CMD ["default"]
