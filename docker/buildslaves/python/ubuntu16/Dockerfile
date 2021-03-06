# Docker container for Ubuntu 16.04

FROM ubuntu:16.04
MAINTAINER build-team@couchbase.com

USER root

# Install Couchbase build dependencies
RUN apt-get update && \
    apt-get install -y build-essential curl git libc6-dbg libssl-dev lsb-release openjdk-8-jdk sudo tar && \
    apt-get install -y libbz2-dev libffi-dev libxml2-dev libxslt1-dev && \
    apt-get clean

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Python 3.6.6
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -LO http://python.org/ftp/python/3.6.6/Python-3.6.6.tar.xz && \
    tar xf Python-3.6.6.tar.xz && \
    cd Python-3.6.6 && \
    ./configure --prefix=/usr/local \
        --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" && \
    make && make altinstall && \
    strip /usr/local/lib/libpython3.6m.so.1.0 && \
    ln -s /usr/local/bin/python3.6 /usr/local/bin/python3 && \
    cd /tmp/deploy && \
    curl -LO https://bootstrap.pypa.io/get-pip.py && \
    python3.6 get-pip.py && \
    cd /tmp && \
    rm -rf deploy

# Repo
RUN curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Jenkins Swarm client jar
RUN curl https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.17/swarm-client-3.17.jar -o /usr/local/lib/swarm-client.jar

# tini, to avoid zombie issues when running with Swarm jar
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Python libs
RUN pip3.6 install pyinstaller

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
USER couchbase
RUN mkdir /home/couchbase/.ssh

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
