# Docker container for SUSE 15, based on openSUSE LEAP

FROM opensuse/leap:15.2
LABEL maintainer="build-team@couchbase.com"

USER root

RUN zypper -n install vim sudo curl && zypper clean

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# tini, to avoid zombie issues when running with Swarm jar
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# JDK for Jenkins
RUN zypper -n install java-1_8_0-openjdk-headless && zypper clean
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.17/swarm-client-3.17.jar \
    -o /usr/local/lib/swarm-client.jar

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repository
RUN zypper -n install \
                binutils \
                ccache \
                curl \
                ed \
                git \
                hostname \
                libffi-devel \
                libnuma-devel \
                libopenssl-devel \
                lsb-release \
                make \
                man \
                ncurses-devel \
                python-devel \
                python-xml \
                rpm-build \
                rsync \
                ruby \
                sqlite3-devel \
                tar \
                unzip \
    && zypper clean

# * CMake (from cmake.org)
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v3.13/cmake-3.13.0-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# Install autoconf and friends - necessary for building some third-party deps
# from source, not for Couchbase. (The "full" version of perl is also required
# for some third-party builds.)
RUN zypper -n install perl m4 autoconf automake libtool && zypper clean

# * ccache symlinks
RUN ln -s /usr/bin/ccache /home/couchbase/bin/gcc && \
    ln -s /usr/bin/ccache /home/couchbase/bin/g++ && \
    ln -s /usr/bin/ccache /home/couchbase/bin/cc && \
    ln -s /usr/bin/ccache /home/couchbase/bin/c++

# * repo
RUN curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# * Install cbdep
RUN curl https://packages.couchbase.com/cbdep/0.9.18/cbdep-0.9.18-linux -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

# * Install miniconda3
# One of the benefits is: repo tool requires python 3.5+; the OS comes with python2.  miniconda3 is a flexible way
# of installing python on a system
RUN cbdep install -d /home/couchbase miniconda3-py39 4.9.2 && \
    chown -R couchbase:couchbase /home/couchbase/miniconda3-4.9.2

# Set LANG
ENV LANG=en_US.UTF-8

# GCC (from couchbasebuild/suse-15-gcc)
COPY build/local /usr/local
RUN  (cat /etc/ld.so.conf ; echo "/usr/local/lib64") > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

RUN set -x \
        && update-alternatives --install /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
        && update-alternatives --install /usr/bin/g++ g++ /usr/local/bin/g++ 100

ENV AGENT_VERSION=4.3

# RUN zypper install -y git-lfs && zypper clean

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
