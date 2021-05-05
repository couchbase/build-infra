# Docker container for Ubuntu 20.04

# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
FROM couchbasebuild/ubuntu-20-gcc:${GCC_VER} AS gcc

# This is the actual build agent base image
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

ARG SWARM_CLIENT_VER
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VER}/swarm-client-${SWARM_CLIENT_VER}.jar \
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

ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN set -x \
    && mkdir /tmp/deploy \
    && curl -f https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh \
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

RUN apt-get update && apt-get install git-lfs && rm -rf /var/lib/apt/lists/*

ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
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

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
# Historic gcc 7.5.0
COPY --from=couchbasebuild/ubuntu-2004-gcc:7.5.0 /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

RUN set -x \
        && update-alternatives --install /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
        && update-alternatives --install /usr/bin/g++ g++ /usr/local/bin/g++ 100

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Expose SSH daemon and run our builder startup script
EXPOSE 22

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
