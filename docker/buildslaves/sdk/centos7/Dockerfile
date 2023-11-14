# Docker container for Centos7

FROM centos:centos7.4.1708
LABEL maintainer="build-team@couchbase.com"

USER root
RUN yum install --setopt=keepcache=0 -y sudo deltarpm && \
    yum clean all

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
# * Packages from the base CentOS repository
# * CentOS SCLs for devtoolset-8 (devtoolset-9-gcc-c++),
#   more info at https://www.softwarecollections.org/en/scls/rhscl/devtoolset-8/
RUN yum install --setopt=keepcache=0 -y epel-release centos-release-scl && \
    yum install --setopt=keepcache=0 -y \
                bzip2-devel \
                cmake \
                cmake3 \
                ed \
                git \
                glibc.i686 \
                libev-devel \
                libevent-devel \
                libffi-devel \
                libicu \
                libunwind \
                libuv-devel \
                libxml2-devel \
                make \
                man \
                ncurses-devel \
                numactl-devel \
                oniguruma-devel \
                openssl-devel \
                openssl-libs \
                openssh-clients \
                perl-XML-XPath \
                python-devel \
                python-pip \
                python-virtualenv \
                redhat-lsb-core \
                rpm-build \
                ruby rubygems rubygem-rake \
                tar \
                unzip \
                wget \
                which \
                llvm-toolset-7.0 \
                llvm-toolset-7.0-clang-analyzer \
                llvm-toolset-7.0-clang-tools-extra \
                llvm-toolset-7.0-git-clang-format \
                devtoolset-9-gcc-c++ \
                ccache && \
    yum clean all

# Dev basic tools
RUN yum groupinstall -y --setopt=keepcache=0 "Development Tools" && \
    yum clean all

# JDK for Jenkins
RUN yum install -y --setopt=keepcache=0 java-11-openjdk && \
    yum clean all

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
    sudo yum install -y --setopt=keepcache=0 sbt && \
    yum clean all
RUN mkdir /tmp/deploy && \
    curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-4.10-bin.zip && \
    curl -L -o /tmp/deploy/maven.zip https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.5.4/apache-maven-3.5.4-bin.zip && \
    cd /usr/local && \
    unzip /tmp/deploy/gradle.zip && \
    unzip /tmp/deploy/maven.zip && \
    ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin && \
    rm -rf /tmp/deploy

# add OpenSSL 1.1.1
ARG OPENSSL_VERSION=1.1.1l
ARG OPENSSL_PATH=/usr/local/openssl
RUN yum install -y pcre-devel zlib-devel gd-devel perl-ExtUtils-Embed libxslt-devel perl-Test-Simple && \
    yum clean all
RUN cd /tmp && \
    curl -L -o openssl-$OPENSSL_VERSION.tar.gz https://www.openssl.org/source/old/1.1.1/openssl-$OPENSSL_VERSION.tar.gz && \
    tar -xvf openssl-$OPENSSL_VERSION.tar.gz && \
    mv openssl-$OPENSSL_VERSION openssl && \
    cd openssl && \
    ./config --prefix=$OPENSSL_PATH --openssldir=$OPENSSL_PATH shared zlib-dynamic && \
    make -j4 && \
    make install && \
    rm -rf /tmp/openssl && \
    rm -f /tmp/openssl-1.1.1l.tar.gz
ENV CPPFLAGS=-I$OPENSSL_PATH/include/openssl
ENV LDFLAGS="$LDFLAGS -Wl,-rpath,$OPENSSL_PATH"
ENV LD_LIBRARY_PATH=$OPENSSL_PATH/lib:$LD_LIBRARY_PATH

# install pyenv dependencies
RUN yum install -y zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel tk-devel libffi-devel xz-devel patch && \
    yum clean all

# libcouchbase
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L -o couchbase-release.rpm http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-4-x86_64.rpm && \
    rpm -iv couchbase-release.rpm && \
    yum install -y --setopt=keepcache=0 libcouchbase-devel libcouchbase2-libevent libcouchbase2-libev libcouchbase2-bin && \
    yum clean all && \
    cd /tmp && \
    rm -rf /tmp/deploy

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
