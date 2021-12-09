# Docker container for Centos8

FROM centos:8
LABEL maintainer="build-team@couchbase.com"

USER root

# Not at all sure about this workaround
RUN rpm --rebuilddb || ( \
        rm -rf /var/lib/rpm && \
        mv /var/lib/rpmrebuild* /var/lib/rpm \
)

RUN dnf install -y sudo

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
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm dnf-plugins-core && \
    dnf config-manager --set-enabled powertools

# * Packages from the base CentOS repository and EPEL
RUN dnf install -y \
                bzip2-devel \
                cmake \
                ed \
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
                tar \
                unzip \
                which \
                wget

# Dev basic tools
RUN dnf groupinstall -y "Development Tools"

# JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11/OpenJDK11U-jre_x64_linux_hotspot_11.0.4_11.tar.gz -o openjre.tar.gz && \
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
    curl -L -o /tmp/deploy/maven.zip http://apache.mirrors.tds.net/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.zip && \
    cd /usr/local && \
    unzip /tmp/deploy/gradle.zip && \
    unzip /tmp/deploy/maven.zip && \
    ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin && \
    rm -rf /tmp/deploy

# Temp install step for "cbdep" tool
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
