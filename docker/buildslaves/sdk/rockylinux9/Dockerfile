# Docker container for Rocky Linux 9

FROM quay.io/rockylinux/rockylinux:9.4
LABEL maintainer="build-team@couchbase.com"

USER root
RUN dnf install --setopt=keepcache=0 -y sudo && \
    dnf clean all

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
RUN dnf install --setopt=keepcache=0 -y \
                epel-release \
    && \
    dnf install --setopt=keepcache=0 -y --enablerepo=devel \
                doxygen \
                libuv-devel \
                ninja-build \
                oniguruma-devel \
                redhat-lsb-core \
    && \
    dnf install --setopt=keepcache=0 -y --enablerepo=crb \
                python-virtualenv \
    && \
    dnf install --setopt=keepcache=0 -y \
                @"Development Tools" \
                bzip2 \
                bzip2-devel \
                ccache \
                clang-analyzer \
                clang-tools-extra \
                cmake \
                ed \
                gcc-c++ \
                git \
                git-clang-format \
                glibc-langpack-en \
                java-11-openjdk \
                java-latest-openjdk-devel \
                jsoncpp-devel \
                libasan \
                libev-devel \
                libevent-devel \
                libffi-devel \
                libicu-devel \
                libunwind \
                libxml2-devel \
                make \
                man \
                maven \
                ncurses-devel \
                numactl-devel \
                openssl-devel \
                openssl-libs \
                patch \
                perl-XML-XPath \
                php-devel \
                php-pear \
                plantuml \
                python \
                python-boto3 \
                python-devel \
                python-pip \
                rbenv \
                readline-devel \
                repo \
                rpm-build \
                ruby-build-rbenv \
                ruby-devel \
                rubygem-rake \
                rubygems \
                sqlite \
                sqlite-devel \
                tar \
                tk-devel \
                unzip \
                valgrind \
                wget \
                which \
                xz-devel \
                zlib-devel \
    && \
    curl https://www.scala-sbt.org/sbt-rpm.repo > /etc/yum.repos.d/sbt-rpm.repo && \
    dnf install -y --setopt=keepcache=0 sbt \
    && \
    dnf clean all

RUN mkdir /tmp/deploy && \
    curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-8.10-bin.zip && \
    cd /usr/local && \
    unzip /tmp/deploy/gradle.zip && \
    ln -s  /usr/local/gradle-*/bin/gradle /usr/local/bin && \
    rm -rf /tmp/deploy

# Ensure /opt/cbdeps is writable
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# Temp install step for "cbdep" tool
ARG CACHEBUST=1
RUN curl https://s3.amazonaws.com/packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep
ENV PATH=$PATH:/usr/local/bin

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
