# Docker container for AlmaLinux 8

FROM almalinux:8
LABEL maintainer="build-team@couchbase.com"

USER root

RUN dnf install -y sudo && dnf clean all

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
    && dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm dnf-plugins-core \
    && dnf config-manager --set-enabled powertools \
    && dnf clean all

# * Packages from the base CentOS repository and EPEL
RUN set -x \
    && dnf install -y \
                bzip2-devel \
                ed \
                gcc-toolset-12-gcc-c++ \
                git \
                glibc.i686 \
                libev-devel \
                libevent-devel \
                libffi-devel \
                libicu \
                libunwind-devel \
                libxml2-devel \
                make \
                man \
                ncurses-devel \
                numactl-devel \
                oniguruma-devel \
                openssh-clients \
                openssl-devel \
                python3-devel \
                python3-pip \
                python3-virtualenv \
                redhat-lsb-core \
                rpm-build \
                ruby rubygems rubygem-rake \
                sqlite-devel \
                tar \
                unzip \
                which \
                wget \
    && dnf clean all

# Dev basic tools
RUN dnf groupinstall -y "Development Tools" && dnf clean all

# Initial install of cbdep for installing JDK, etc
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

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Ensure /opt/cbdeps is writable
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# SBT, Gradle, Maven
RUN set -x \
    && curl https://www.scala-sbt.org/sbt-rpm.repo > /etc/yum.repos.d/sbt-rpm.repo \
    && sudo yum install -y --setopt=keepcache=0 sbt \
    && yum clean all
RUN set -x \
    && mkdir /tmp/deploy \
    && curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-4.10-bin.zip \
    && curl -L -o /tmp/deploy/maven.zip https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.zip  \
    && cd /usr/local \
    && unzip /tmp/deploy/gradle.zip \
    && unzip /tmp/deploy/maven.zip \
    && ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin \
    && rm -rf /tmp/deploy

# Add our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
RUN mkdir /home/couchbase/.ssh && chown couchbase:couchbase /home/couchbase/.ssh

# Temp install step for "cbdep" tool
ARG CACHEBUST=1
RUN curl https://s3.amazonaws.com/packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep
USER couchbase

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
