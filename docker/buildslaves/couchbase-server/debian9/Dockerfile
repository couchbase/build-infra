# Docker container for Debian 9.1 (Stretch)

# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
FROM couchbasebuild/debian-9-gcc:${GCC_VER} AS gcc

# This is the actual build agent base image
FROM debian:9.1
LABEL maintainer="build-team@couchbase.com"

USER root

# Install SSH server
RUN apt-get update && \
    apt-get install -y openssh-server sudo curl && \
    rm -f /var/cache/apt/archives/*.deb && \
    mkdir /var/run/sshd # update 3

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

ARG SWARM_CLIENT_VER
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VER}/swarm-client-${SWARM_CLIENT_VER}.jar \
    -o /usr/local/lib/swarm-client.jar

# tini, to avoid zombie issues when running with Swarm jar
ARG TINI_VER
ADD https://github.com/krallin/tini/releases/download/v${TINI_VER}/tini /tini
RUN chmod +x /tini

# Install Couchbase build dependencies.
# Note: lsb-release currently required for "cbdeps" third-party build
# mechanism, but we hope to remove that requirement as it brings in
# a lot of unnecessary packages.

RUN apt-get update && \
    apt-get install -y \
        ccache \
        git-core \
        pkg-config \
        tar \
        libssl-dev \
        libnuma-dev \
        zlib1g-dev \
        rubygems \
        rake \
        ncurses-dev \
        python-dev \
        devscripts \
        debhelper \
        ed \
        man \
        pixz \
        lsb-release \
        libsqlite3-dev && \
    apt-get clean

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
# Historic gcc 7.3.0
COPY --from=couchbasebuild/debian-9-gcc:7.3.0 /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# Install autoconf and friends - necessary for building some third-party deps
# from source, not for Couchbase.
RUN apt-get update && apt-get install -y m4 autoconf automake libtool

RUN echo 'PATH="/usr/lib/ccache:$PATH"' >> /home/couchbase/.profile

ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo && \
    cd /tmp && rm -rf /tmp/deploy

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    sed -ie '/en_US.UTF-8/s/^# //' /etc/locale.gen && \
    locale-gen

# Add rsync for pulling config+secrets at startup
RUN set -x \
        && apt update \
        && apt install -y rsync \
        && apt clean

# RUN apt-get update && apt-get install git-lfs && rm -rf /var/lib/apt/lists/*

ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Install asciidoctor
ARG ASCIIDOCTOR_VER
RUN gem install asciidoctor -v ${ASCIIDOCTOR_VER}

# Set LANG
ENV LANG=en_US.UTF-8

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Expose SSH daemon and run our builder startup script
EXPOSE 22
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
