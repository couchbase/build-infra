# Docker container for Centos 6.9

FROM centos:6.9
MAINTAINER build-team@couchbase.com

ENV PYTHON_VERSION=2.7.14 LD_RUN_PATH=/usr/local/lib

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    mkdir -p /etc/sudoers.d && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repository
RUN yum install --setopt=keepcache=0 -y epel-release && \
    yum install --setopt=keepcache=0 -y \
    sudo \
    bzip2-devel \
    centos-release-scl \
    http://opensource.wandisco.com/centos/6/git/x86_64/wandisco-git-release-6-1.noarch.rpm \
    glibc.i686 \
    libuv-devel \
    libev-devel \
    libevent-devel \
    libxslt \
    numactl-devel \
    openssl-devel \
    openssh-clients \
    redhat-lsb-core \
    rpm-build \
    tar \
    unzip \
    which \
    zlib-devel \
    curl \
    wget \
    java-1.8.0-openjdk && \
    yum clean packages

# devtoolset 6 (plus git from wandisco)
RUN yum install --setopt=keepcache=0 -y \
    git \
    devtoolset-6-gcc \
    devtoolset-6-gcc-c++ \
    devtoolset-6-binutils \
    devtoolset-6-make \
    devtoolset-6-elfutils && \
    yum clean packages && \
    for file in /opt/rh/devtoolset-6/root/usr/bin/*; do ln -s $file /usr/local/bin; done

# Build and install Python 2.7 and useful base tools
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xvf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-shared --prefix=/usr/local \
    && make \
    && make altinstall \
    && cd / \
    && rm -rf Python-${PYTHON_VERSION}*

# Install pip and virtualenv for system Python
RUN mkdir /tmp/deploy && \
    curl -o get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    python2.7 get-pip.py && \
    pip install virtualenv && \
    rm -rf /tmp/deploy

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

# Temp install step for "cbdep" tool
RUN curl http://nas-n.mgt.couchbase.com/builds/downloads/cbdep/cbdep.linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

# Build tools
RUN curl https://bintray.com/sbt/rpm/rpm > /etc/yum.repos.d/bintray-sbt-rpm.repo && \
    sudo yum install -y --setopt=keepcache=0 sbt
RUN mkdir /tmp/deploy && \
    curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-4.10-bin.zip && \
    curl -L -o /tmp/deploy/maven.zip http://apache.mirrors.tds.net/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip && \
    cd /usr/local && \
    unzip /tmp/deploy/gradle.zip && \
    unzip /tmp/deploy/maven.zip && \
    ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin && \
    rm -rf /tmp/deploy

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
