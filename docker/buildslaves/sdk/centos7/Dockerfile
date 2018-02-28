# Docker container for Centos7

FROM centos:centos7.4.1708
MAINTAINER build-team@couchbase.com

USER root
RUN yum clean all && \
    yum install --setopt=keepcache=0 -y sudo deltarpm

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repository
RUN yum install --setopt=keepcache=0 -y \
                ed \
                glibc.i686 \
                libxml2-devel \
                make \
                man \
                ncurses-devel \
                numactl-devel \
                openssh-clients openssl-devel \
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
                python-pip

# Dev basic tools
RUN yum groupinstall -y "Development Tools"

# JDK for Jenkins
RUN yum -y install java-1.8.0-openjdk && yum clean packages

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Jenkins Swarm client jar
RUN curl https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.8/swarm-client-3.8.jar -o /usr/local/lib/swarm-client.jar

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
USER couchbase
RUN mkdir /home/couchbase/.ssh
