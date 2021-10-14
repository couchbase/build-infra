# syntax=docker/dockerfile:1.3
# Docker container for Single Linux build. Currently based on
# Centos 7 as it has the oldest glibc of the distros we support.

# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
FROM couchbasebuild/centos-7-gcc:${GCC_VER} AS gcc


# Start of compile-only stages


# First a base compile image that has some recurring dependencies
FROM centos:centos7.9.2009 AS base-compile
LABEL imagename=base-compile

RUN yum install -y curl deltarpm sudo
RUN yum groupinstall -y "Development Tools"
RUN yum install -y bzip2-devel libffi-devel ncurses-devel openssl-devel openssl-devel readline-devel zlib-devel


# autoconf and friends - necessary for building some third-party deps
# from source, not for Couchbase.
FROM base-compile AS autoconf-compile
LABEL imagename=autoconf-compile

ARG AUTOCONF_VER
ARG AUTOMAKE_VER
ARG LIBTOOL_VER
RUN yum install -y --setopt=keepcache=0 perl-Data-Dumper m4
RUN cd /tmp && mkdir autoconf automake libtool
RUN curl -Lf http://ftpmirror.gnu.org/autoconf/autoconf-${AUTOCONF_VER}.tar.gz | tar xz --strip-components=1 -C /tmp/autoconf
RUN curl -Lf http://ftpmirror.gnu.org/automake/automake-${AUTOMAKE_VER}.tar.gz | tar xz --strip-components=1 -C /tmp/automake
RUN curl -Lf http://ftpmirror.gnu.org/libtool/libtool-${LIBTOOL_VER}.tar.gz | tar xz --strip-components=1 -C /tmp/libtool
RUN cd /tmp/autoconf && ./configure --prefix=/usr/local && make -j && make install
RUN cd /tmp/automake && ./configure --prefix=/usr/local && make -j && make install
RUN cd /tmp/libtool && ./configure --prefix=/usr/local && make -j && make install


# Ruby
FROM base-compile AS ruby-compile
LABEL imagename=ruby-compile

# Ruby-install
ARG RUBY_INSTALL_MINOR
ARG RUBY_INSTALL_MAJOR
ARG RUBY_INSTALL_PATCH
ARG RUBY_INSTALL_VER="${RUBY_INSTALL_MAJOR}.${RUBY_INSTALL_MINOR}.${RUBY_INSTALL_PATCH}"
RUN mkdir /tmp/ruby-install
RUN curl -Lf /tmp/ruby-install-${RUBY_INSTALL_VER}.tar.gz https://github.com/postmodern/ruby-install/archive/v${RUBY_INSTALL_VER}.tar.gz -o - \
        | tar xz --strip-components=1 -C /tmp/ruby-install
WORKDIR /tmp/ruby-install
RUN sudo make -j install

# Ruby itself
ARG RUBY_MAJOR
ARG RUBY_MINOR
ARG RUBY_PATCH
RUN ruby-install --prefix /usr/local -j -- ${RUBY_MAJOR}.${RUBY_MINOR}.${RUBY_PATCH}


# Python
FROM base-compile AS python-compile
LABEL imagename=python-compile

ARG PYTHON3_MAJOR
ARG PYTHON3_MINOR
ARG PYTHON3_PATCH
RUN mkdir /tmp/python
RUN curl -Lf https://www.python.org/ftp/python/${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}/Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}.tgz -o - \
        | tar xz --strip-components=1 -C /tmp/python
WORKDIR /tmp/python
RUN ./configure --enable-optimizations --prefix=/usr/local
RUN make -j altinstall
RUN ln -s python${PYTHON3_MAJOR}.${PYTHON3_MINOR} /usr/local/bin/python${PYTHON3_MAJOR}
RUN curl -f https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
RUN /usr/local/bin/python3 /tmp/get-pip.py


# Git
FROM base-compile AS git-compile
LABEL imagename=git-compile

ARG GIT_VER
RUN mkdir /tmp/git
RUN yum install -y curl-devel expat-devel gettext-devel perl-devel
RUN curl -Lf https://www.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.gz -o - \
        | tar xz --strip-components=1 -C /tmp/git
WORKDIR /tmp/git
RUN make -j prefix=/usr/local install


# Ccache
FROM base-compile AS ccache-compile
LABEL imagename=ccache-compile

ARG CCACHE_VER
RUN mkdir /tmp/ccache
RUN curl -Lf https://www.samba.org/ftp/ccache/ccache-${CCACHE_VER}.tar.bz2 -o - | tar xj --strip-components=1 -C /tmp/ccache
WORKDIR /tmp/ccache
RUN ./configure --prefix=/usr/local && make -j && make install


# -----------------------------------------
# This is the actual build agent base image
# -----------------------------------------

FROM centos:centos7.9.2009 AS build
LABEL maintainer="build-team@couchbase.com"

# Set LANG
ENV LANG=en_US.UTF-8

USER root

# tini, to avoid zombie issues when running with Swarm jar
ARG TINI_VER
ADD https://github.com/krallin/tini/releases/download/v${TINI_VER}/tini /tini
RUN chmod +x /tini

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repositories
RUN yum install --setopt=keepcache=0 -y \
                binutils \
                ed \
                glibc-devel \
                make \
                man \
                ncurses-devel \
                openssh-clients \
                openssh-server \
                rpm-build \
                rpm-sign \
                sudo \
                tar \
                unzip \
                which \
    && yum clean all

# Set up for SSH daemon
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

# clean up nsswitch
RUN sed -ri 's/^hosts.*/hosts:      files dns/' /etc/nsswitch.conf

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group && \
    usermod -G wheel root

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
RUN for prog in gcc g++; do ln -s /opt/gcc-${GCC_VER}/bin/${prog} /usr/local/bin; done
RUN for lib in /opt/gcc-${GCC_VER}/lib64/libstd*; do ln -s ${lib} /usr/local/lib64; done
RUN echo /usr/local/lib64 > /etc/ld.so.conf.d/gcc10.conf && ldconfig

# Autoconf and friends
COPY --from=autoconf-compile /usr/local/ /usr/local/
RUN yum install -y m4 && yum clean all

# * CMake (from cmake.org)
ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl -Lf https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# * repo
RUN set -x \
    && curl -Lf https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# Git
COPY --from=git-compile /usr/local/ /usr/local/

# Python 3 & pip
COPY --from=python-compile /usr/local/ /usr/local/

# Ruby
RUN yum install -y libyaml && yum clean all
COPY --from=ruby-compile /usr/local/ /usr/local/

# Ccache
COPY --from=ccache-compile /usr/local/ /usr/local/

# Install asciidoctor
ARG ASCIIDOCTOR_VER
RUN gem install asciidoctor -v ${ASCIIDOCTOR_VER}

# Install perl Data::Dumper (used by at least PCRE build script)
RUN yum install -y --setopt=keepcache=0 perl-Data-Dumper && yum clean all

# JNLP agent (for use in EC2 agents)
ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar
ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Jenkins Swarm jar
RUN yum install -y java-11-openjdk-headless rsync && \
    yum clean all
ARG SWARM_CLIENT_VER
RUN curl -Lf \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VER}/swarm-client-${SWARM_CLIENT_VER}.jar \
    -o /usr/local/lib/swarm-client.jar

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Our tools
ARG CBDEP_VER
ARG PATCH_VIA_GERRIT_VER
RUN curl -Lf https://packages.couchbase.com/cbdep/${CBDEP_VER}/cbdep-${CBDEP_VER}-linux-$(uname -m) -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep
RUN curl -Lf https://packages.couchbase.com/patch_via_gerrit/${PATCH_VIA_GERRIT_VER}/patch_via_gerrit-${PATCH_VIA_GERRIT_VER}-linux-$(uname -m) -o /usr/local/bin/patch_via_gerrit && \
    chmod a+x /usr/local/bin/patch_via_gerrit

# Docker
ARG DOCKER_VER
RUN curl -Lf https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VER}.tgz \
        | tar xz --strip-components=1 -C /usr/local/bin
RUN usermod -a -G 999 couchbase

# This might be temporary, if we can get parallel dpkg-buildpackage working.
RUN yum install -y http://ftp5.gwdg.de/pub/opensuse/repositories/home:/JeanVEGA/CentOS_7/x86_64/pixz-1.0.7-40.2.x86_64.rpm && yum clean all

# Need to create some directories so that the swarm stackfile can mount
# on top of them without messing up permisions / ownership.
RUN mkdir -p /home/couchbase/jenkins/workspace /home/couchbase/.cbdepscache /home/couchbase/.cbdepcache/ /home/couchbase/.ccache \
    && chown -R couchbase:couchbase /home/couchbase

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Expose SSH daemon and run our builder startup script
EXPOSE 22
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
