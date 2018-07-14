# Docker container for Ubuntu 14.04

# See https://github.com/ceejatec/naked-docker/ for details about the
# construction of the base image.

FROM ceejatec/naked-ubuntu:14.04
MAINTAINER ceej@couchbase.com

USER root

# Install SSH server
RUN apt-get update && \
    apt-get install -y openssh-server curl && \
    rm -f /var/cache/apt/archives/*.deb && \
    mkdir /var/run/sshd # update 2

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Jenkins Swarm jar
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L \
    https://download.java.net/openjdk/jdk8u40/ri/openjdk-8u40-b25-linux-x64-10_feb_2015.tar.gz -o jdk.tgz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/jdk.tgz && \
    ln -s java* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy
ENV JAVA_HOME=/usr/local/java
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
        ed \
        man \
        pixz && \
    apt-get clean

# GCC (from couchbasebuild/ubuntu-1404-gcc)
COPY build/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# paramiko for testrunner
RUN apt-get update && \
    apt-get install -y python-paramiko

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
    rm -f /var/cache/apt/archives/*.deb
RUN mkdir /tmp/deploy && \
    curl -L http://ftpmirror.gnu.org/autoconf/autoconf-2.69.tar.gz -o /tmp/deploy/autoconf-2.69.tar.gz && \
    cd /tmp/deploy && tar -xzf autoconf-2.69.tar.gz && \
    cd autoconf-2.69 && ./configure --prefix=/usr/local && make && make install && \
    curl -L http://ftpmirror.gnu.org/automake/automake-1.14.tar.gz -o /tmp/deploy/automake-1.14.tar.gz && \
    cd /tmp/deploy && tar -xzf automake-1.14.tar.gz && \
    cd automake-1.14 && ./configure --prefix=/usr/local && make && make install && \
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

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ADD .ssh /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

