# Docker container for Ubuntu 18.04

FROM ubuntu:18.04
MAINTAINER build-team@couchbase.com

USER root

# Install SSH server and sudo
RUN apt-get update && \
    apt-get install -y openssh-server sudo curl && \
    apt-get clean && \
    mkdir /var/run/sshd

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Jenkins Swarm jar
RUN apt-get update && \
    apt-get install -y openjdk-8-jre-headless && \
    apt-get clean
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.13/swarm-client-3.13.jar \
    -o /usr/local/lib/swarm-client.jar

# tini, to avoid zombie issues when running with Swarm jar
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Install Couchbase build dependencies
RUN apt-get update && \
    apt-get install -y \
        ccache \
        git-core \
        tar \
        libssl-dev \
        libnuma-dev \
        ruby \
        rake \
        ncurses-dev \
        python-dev \
        devscripts \
        debhelper \
        dh-systemd \
        ed \
        man \
        pkg-config \
        pixz && \
    apt-get clean

# GCC (from couchbasebuild/ubuntu-1804-gcc)
COPY build/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# paramiko for testrunner
RUN apt-get update && \
    apt-get install -y python-paramiko

# pygerrit (for toy builds)
RUN apt-get install -y python-pip && \
    pip install pygerrit2

# Install third-party build dependencies. Note: software-properties-common
# is only required for add-apt-repository; add-apt-repository is only
# required to get python2.6; and python2.6 is only required for gyp, which
# is part of the v8 build. python2.6 is also required for our compiling of
# pysqlite and pysnappy, and for that we even need python2.6-dev.
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y m4 python2.6 python2.6-dev && \
    apt-get clean
RUN mkdir /tmp/deploy && \
    curl -L http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz -o /tmp/deploy/autoconf-2.69.tar.gz && \
    cd /tmp/deploy && tar -xzf autoconf-2.69.tar.gz && \
    cd autoconf-2.69 && ./configure --prefix=/usr/local && make && make install && \
    curl -L http://ftpmirror.gnu.org/automake/automake-1.15.1.tar.gz -o /tmp/deploy/automake-1.15.1.tar.gz && \
    cd /tmp/deploy && tar -xzf automake-1.15.1.tar.gz && \
    cd automake-1.15.1 && ./configure --prefix=/usr/local && make && make install && \
    curl -L http://ftpmirror.gnu.org/libtool/libtool-2.4.2.tar.gz -o /tmp/deploy/libtool-2.4.2.tar.gz && \
    cd /tmp/deploy && tar -xzf libtool-2.4.2.tar.gz && \
    cd libtool-2.4.2 && ./configure --prefix=/usr/local && make && make install && \
    cd /tmp && rm -rf /tmp/deploy

RUN echo 'PATH="/usr/lib/ccache:$PATH"' >> /home/couchbase/.profile
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v3.6/cmake-3.6.1-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo && \
    cd /tmp && rm -rf /tmp/deploy

# Python 3-specific stuff for build scripts, mostly for Jira.
RUN apt-get update && \
    apt-get -y install python3-pip libffi-dev && \
    pip3 install lxml oauthlib==0.7.2 jwt pycrypto jira boto3 pbr && \
    apt-get autoremove --purge -y && \
    apt-get clean && \
    ccache --clear

# Python 2-specific stuff for build scripts, mostly old build-sanity stuff.
RUN apt-get update && \
    apt-get -y install python-pip && \
    pip install jenkinsapi && \
    apt-get clean

#s3cmd for upload script
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y s3cmd  && \
    apt-get clean

# Set 8G ccache limit
USER couchbase
RUN ccache -M 8G
USER root

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Set AWS credentials file environmental variable
ENV AWS_SHARED_CREDENTIALS_FILE=/home/couchbase/.ssh/aws-credentials

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ADD .ssh /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
