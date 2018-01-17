# Docker container for repo_upload program on CentOS 7.4
#
# Contains the repo_upload program for handling the Yum uploads to S3

FROM centos:7.4.1708
MAINTAINER build-team@couchbase.com

USER root
ENV PYTHON_VERSION=3.6.3 LD_RUN_PATH=/usr/local/lib EDITION=enterprise

# Install some prerequisites and additional needed software
RUN yum clean all && yum swap -y fakesystemd systemd && \
    yum install --setopt=keepcache=0 -y \
            bzip2-devel \
            createrepo \
            deltarpm \
            epel-release \
            git \
            gcc \
            make \
            openssl-devel \
            readline-devel \
            rpm-sign \
            sqlite-devel \
            sudo \
            tar \
            wget \
            yum-utils \
            zlib-dev

# Install CMake and repo
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v3.6/cmake-3.6.1-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo && \
    cd /tmp && rm -rf /tmp/deploy

# Create couchbase user with password-less sudo privs
RUN groupadd -g 1000 couchbase && \
    useradd couchbase -g couchbase -u 1000 -G wheel -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# Build and install Python 3.6 and useful base tools
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xvf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-shared --prefix=/usr/local \
    && make \
    && make altinstall \
    && cd / \
    && rm -rf Python-${PYTHON_VERSION}*

# Update locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8

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

COPY setup_yum_repo_upload.sh /usr/sbin/

ENTRYPOINT ["/usr/sbin/setup_yum_repo_upload.sh"]
CMD ["default"]
