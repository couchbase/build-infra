# Docker container for Centos7

ARG GCC_VER_MAJOR=10
ARG GCC_VER_MINOR=2
ARG GCC_VER_PATCH=0
ARG ARCH=x86_64
FROM couchbasebuild/amzn-2-gcc:${GCC_VER_MAJOR}.${GCC_VER_MINOR}.${GCC_VER_PATCH}-${ARCH} AS gcc

# This is the actual build agent base image
FROM amazonlinux:2.0.20190228
LABEL maintainer="build-team@couchbase.com"

USER root
RUN yum clean all && \
    yum install --setopt=keepcache=0 -y sudo deltarpm

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repository
RUN yum install --setopt=keepcache=0 -y \
                ed \
                glibc.i686 \
                bzip2-devel \
                libicu \
                libunwind \
                libuv-devel \
                libev-devel \
                libevent-devel \
                libffi-devel \
                libxml2-devel \
                openssl11-devel \
                openssl11-static \
                make \
                man \
                ncurses-devel \
                numactl-devel \
                openssh-clients \
                python-devel \
                python-pip \
                python-virtualenv \
                redhat-lsb-core \
                rpm-build \
                ruby rubygems rubygem-rake \
                tar \
                unzip \
                which \
                git \
                cmake \
                python-pip \
                wget \
                python-pip \
                ccache

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# Dev basic tools
RUN yum groupinstall -y "Development Tools"

# JRE for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -Lf https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.5%2B8/OpenJDK17U-jre_x64_linux_hotspot_17.0.5_8.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# CMake
RUN mkdir /tmp/deploy && \
    curl -L https://cmake.org/files/v3.21/cmake-3.21.4-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm /usr/local/bin/cmake-gui && \
    rm -rf /tmp/deploy

# Ensure /opt/cbdeps is writable
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# Build tools
RUN curl https://www.scala-sbt.org/sbt-rpm.repo > /etc/yum.repos.d/sbt-rpm.repo && \
    sudo yum install -y --setopt=keepcache=0 sbt
RUN mkdir /tmp/deploy && \
    curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-4.10-bin.zip && \
    curl -L -o /tmp/deploy/maven.zip https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip && \
    cd /usr/local && \
    unzip /tmp/deploy/gradle.zip && \
    unzip /tmp/deploy/maven.zip && \
    ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin && \
    rm -rf /tmp/deploy

# libcouchbase - commented out until we have libcouchbase for amzn2 available in repos
#RUN mkdir /tmp/deploy && \
#    cd /tmp/deploy && \
#    curl -L -o couchbase-release.rpm http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-4-x86_64.rpm && \
#    rpm -iv couchbase-release.rpm && \
#    yum install -y libcouchbase-devel libcouchbase2-libevent libcouchbase2-libev libcouchbase2-bin && \
#    cd /tmp && \
#    rm -rf /tmp/deploy

# GCC - need to redundantly declare GCC ARG here
ARG GCC_VER_MAJOR
ARG GCC_VER_MINOR
ARG GCC_VER_PATCH
# Copy gcc to /opt
COPY --from=gcc /opt/gcc-${GCC_VER_MAJOR}.${GCC_VER_MINOR}.${GCC_VER_PATCH} /opt/gcc-${GCC_VER_MAJOR}.${GCC_VER_MINOR}.${GCC_VER_PATCH}
RUN ln -sf /opt/gcc-${GCC_VER_MAJOR}.${GCC_VER_MINOR}.${GCC_VER_PATCH}/bin/gcc /usr/local/bin/gcc${GCC_VER_MAJOR} && \
    ln -sf /opt/gcc-${GCC_VER_MAJOR}.${GCC_VER_MINOR}.${GCC_VER_PATCH}/bin/g++ /usr/local/bin/g++${GCC_VER_MAJOR}

# Install "cbdep" for `couchbase` user
# CBD-6552, cbdep symbolic link in /home/couchbase/.local/bin often goes missing.
# Ensure cbdep is on PATH by add "/home/couchbase/.local/share/uv/tools/cbdep/bin" to PATH.
RUN echo -n ":/home/couchbase/.local/bin:/home/couchbase/.local/share/uv/tools/cbdep/bin" >> /etc/path
ENV PATH="/home/couchbase/.local/bin:/home/couchbase/.local/share/uv/tools/cbdep/bin:${PATH}"
USER couchbase
RUN set -x \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && uv tool install cbdep
USER root

# Add hook to update cbdep on each container start
COPY build/update-cbdep.sh /usr/sbin/couchhook.d/update-cbdep.sh

# Enable disk/memory healthchecks
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

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
