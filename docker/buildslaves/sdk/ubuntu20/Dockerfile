# Docker container for Ubuntu 20.04

FROM ubuntu:20.04
LABEL maintainer=build-team@couchbase.com

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Install Couchbase build dependencies
RUN apt-get update && \
    apt-get install -y build-essential curl git libc6-dbg libssl-dev lsb-release openjdk-8-jdk sudo tar && \
    apt-get install -y groff-base python3-dev python3-pip python3-virtualenv gdb gnupg2 && \
    apt-get install -y libuv1-dev libev-dev libevent-dev libbz2-dev libffi-dev && \
    apt-get install -y libunwind8 libicu66 && \
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

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# CMake
RUN mkdir /tmp/deploy && \
    curl -L https://cmake.org/files/v3.9/cmake-3.9.4-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm /usr/local/bin/cmake-gui && \
    rm -rf /tmp/deploy

# Jenkins Swarm client jar
RUN curl https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.8/swarm-client-3.8.jar -o /usr/local/lib/swarm-client.jar

# Ensure /opt/cbdeps is writable
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# Build tools
RUN apt-get update && \
    apt-get install -y apt-transport-https unzip && \
    echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    apt-get update && \
    apt-get install -y sbt && \
    apt-get clean

RUN mkdir /tmp/deploy && \
    curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-4.10-bin.zip && \
    curl -L -o /tmp/deploy/maven.zip http://apache.mirrors.tds.net/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip && \
    cd /usr/local && \
    unzip /tmp/deploy/gradle.zip && \
    unzip /tmp/deploy/maven.zip && \
    ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin && \
    rm -rf /tmp/deploy

# libcouchbase
RUN mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -LO https://packages.couchbase.com/clients/c/repos/deb/couchbase.key \
    && apt-key add couchbase.key \
    && echo "deb https://packages.couchbase.com/clients/c/repos/deb/ubuntu2004 focal focal/main" > /etc/apt/sources.list.d/libcouchbase.list \
    && apt update \
    && apt install libcouchbase3 libcouchbase-dev libcouchbase3-tools libcouchbase-dbg libcouchbase3-libev libcouchbase3-libevent

# Temp install step for "cbdep" tool
ARG CACHEBUST=1
RUN curl http://downloads.build.couchbase.com/cbdep/cbdep.linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
USER couchbase
RUN mkdir /home/couchbase/.ssh

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
