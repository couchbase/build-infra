# Docker container for Ubuntu 20.04

FROM ubuntu:20.04
LABEL maintainer="build-team@couchbase.com"

USER root

# Install sudo and curl
RUN set -x \
    && apt-get update \
    && apt-get install -y sudo curl \
    && apt-get clean

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN set -x \
    && useradd couchbase -G sudo -m -s /bin/bash \
    && mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase \
    && echo 'couchbase:couchbase' | chpasswd \
    && sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# JDK and Jenkins Swarm jar
RUN set -x \
    && apt-get update \
    && apt-get install -y openjdk-11-jre-headless \
    && apt-get clean
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.17/swarm-client-3.17.jar \
    -o /usr/local/lib/swarm-client.jar

# Install tzdata, telling it to skip user interaction
RUN set -x \
    && apt-get update \
    && TZ=America/Los_Angeles DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
    && apt-get clean

# Install Couchbase build dependencies
RUN set -x \
    && apt-get update \
    && apt-get install -y \
        ccache \
        debhelper \
        devscripts \
        dh-systemd \
        ed \
        git-core \
        libnuma-dev \
        libsqlite3-dev \
        libssl-dev \
        man \
        ncurses-dev \
        pixz \
        pkg-config \
        python3-dev \
        ruby \
        tar \
        vim \
        zlib1g-dev \
    && apt-get clean \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 100

RUN echo 'PATH="/usr/lib/ccache:$PATH"' >> /home/couchbase/.profile
RUN set -x \
    && mkdir /tmp/deploy \
    && curl https://cmake.org/files/v3.13/cmake-3.13.0-Linux-x86_64.sh -o /tmp/deploy/cmake.sh \
    && (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local \
    && curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo \
    && cd /tmp && rm -rf /tmp/deploy

# Set 8G ccache limit
USER couchbase
RUN ccache -M 8G
USER root

# Update locale
RUN set -x \
    && apt-get update \
    && apt-get install -y locales \
    && apt-get clean \
    && locale-gen en_US.UTF-8

# Add rsync for pulling config+secrets at startup
RUN set -x \
    && apt-get update \
    && apt-get install -y rsync \
    && apt-get clean

ENV AGENT_VERSION=4.3

RUN apt-get update && apt-get install git-lfs && rm -rf /var/lib/apt/lists/*

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Set LANG
ENV LANG=en_US.UTF-8

# Set AWS credentials file environmental variable
ENV AWS_SHARED_CREDENTIALS_FILE=/home/couchbase/.ssh/aws-credentials

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# GCC (from couchbasebuild/ubuntu-2004-gcc)
COPY build/local /usr/local
RUN  (cat /etc/ld.so.conf ; echo "/usr/local/lib64") > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

RUN set -x \
        && update-alternatives --install /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
        && update-alternatives --install /usr/bin/g++ g++ /usr/local/bin/g++ 100

# Expose SSH daemon and run our builder startup script
EXPOSE 22

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
