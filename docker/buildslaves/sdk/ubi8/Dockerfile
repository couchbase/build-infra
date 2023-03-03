# Docker container for Centos8

FROM redhat/ubi8
LABEL maintainer="build-team@couchbase.com"

USER root

# Update base image
RUN yum update --disablerepo=* --enablerepo=ubi-8-appstream-rpms --enablerepo=ubi-8-baseos-rpms -y && yum clean all

RUN yum install -y sudo && yum clean all

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# clean up nsswitch
RUN sed -ri 's/^hosts.*/hosts:      files dns/' /etc/nsswitch.conf

### Install Couchbase build dependencies ######################################
# Add EPEL
RUN set -x \
    && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm  \
    && yum config-manager --set-enabled ubi-8-codeready-builder \
    && yum repolist \
    && yum clean all

# * Packages from the base CentOS repository and EPEL, including things
# from "Development Tools" group that doesn't seem to exist anymore
# (starting with "autoconf" in list below)
RUN yum install -y \
        bzip2-devel \
        ed \
        git \
        glibc.i686 \
        libevent-devel \
        libffi-devel \
        libicu \
        libunwind-devel \
        libxml2-devel \
        make \
        man \
        ncurses-devel \
        openssh-clients \
        openssl-devel \
        python39-devel \
        python39-pip \
        redhat-lsb-core \
        rpm-build \
        ruby rubygems rubygem-rake \
        tar \
        unzip \
        which \
        wget \
        autoconf \
        automake \
        binutils \
        gcc \
        gcc-c++ \
        gdb \
        glibc-devel \
        libtool \
        make \
        pkgconf \
        pkgconf-m4 \
        pkgconf-pkg-config \
        redhat-rpm-config \
        rpm-build \
    && yum clean all
RUN update-alternatives --set python /usr/bin/python3.9

# A few things we have to pull from CentOS 8 PowerTools Stream
COPY CentOS-Stream.repo /etc/yum.repos.d/
RUN yum install -y --enablerepo=centos8-appstream,centos8-baseos,centos8-powertools \
        libev-devel \
        numactl-devel \
        oniguruma-devel \
    && yum clean all

# Initial install of cbdep
RUN curl https://s3.amazonaws.com/packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

# Use cbdep to install Java, CMake
RUN set -x \
    && cbdep install -d /opt openjdk 11.0.16+8 \
    && cd /usr/local \
    && ln -s /opt/openjdk* java \
    && for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done \
    && rm -rf /root/.cbdepcache
RUN set -x \
    && cbdep install -d /opt cmake 3.24.2 \
    && ln -s /opt/cmake-3.24.2/bin/cmake /usr/local/bin \
    && rm -rf /root/.cbdepcache

# Ensure /opt/cbdeps is writable and owned by couchbase
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Build tools
RUN curl https://www.scala-sbt.org/sbt-rpm.repo > /etc/yum.repos.d/sbt-rpm.repo && \
    sudo yum install -y --setopt=keepcache=0 sbt && \
    yum clean all
RUN set -x \
    && mkdir /tmp/deploy \
    && curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-7.5.1-bin.zip \
    && curl -L -o /tmp/deploy/maven.zip https://dlcdn.apache.org/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.zip \
    && cd /usr/local \
    && unzip /tmp/deploy/gradle.zip \
    && unzip /tmp/deploy/maven.zip \
    && ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin \
    && rm -rf /tmp/deploy

# Re-install cbdep with a Docker build cache-busting ARG, so we can quickly
# re-create this image with updated cbdep in future
ARG CACHEBUST=1
RUN curl https://s3.amazonaws.com/packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

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
