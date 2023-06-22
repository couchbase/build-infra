# syntax=docker/dockerfile:1.3
# Docker container for Single Linux build. Currently based on
# Centos 7 as it has the oldest glibc of the distros we support.

ARG GCC_VER
ARG GCC_12_VER
ARG CLANG_9_VER
ARG CLANG_9_TAG
ARG CLANG_15_VER
ARG CLANG_15_TAG
FROM couchbasebuild/single-gcc:${GCC_VER} as gcc_10
FROM couchbasebuild/single-gcc:${GCC_12_VER} as gcc_12
FROM couchbasebuild/single-clang:${CLANG_9_VER}-${CLANG_9_TAG} as clang9
FROM couchbasebuild/single-clang:${CLANG_15_VER}-${CLANG_15_TAG} as clang15

# Start of compile-only stages

# First a base compile image that has some recurring dependencies
FROM centos:centos7.9.2009 AS base-compile
LABEL imagename=base-compile

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN yum install -y --setopt=skip_missing_names_on_install=False curl deltarpm sudo
RUN yum groupinstall -y "Development Tools"
RUN yum install -y --setopt=skip_missing_names_on_install=False bzip2-devel libarchive-devel xz-devel libffi-devel ncurses-devel openssl-devel openssl-devel readline-devel zlib-devel
ENV PATH=/opt/gcc-${GCC_12_VER}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

FROM base-compile AS pixz-compile
WORKDIR /tmp
ARG PIXZ_VERSION=1.0.7
ARG PIXZ_SHA=ed227a0a3147db9380f6fe59cc87cd05
ADD https://github.com/vasi/pixz/releases/download/v${PIXZ_VERSION}/pixz-${PIXZ_VERSION}.tar.gz /tmp/pixz.tar.gz
RUN set -x \
    && echo ${PIXZ_SHA} /tmp/pixz.tar.gz | md5sum -c - \
    && mkdir /tmp/pixz && cd /tmp/pixz \
    && tar xf /tmp/pixz.tar.gz --strip-components=1 \
    && ./configure --prefix=/usr/local \
    && make -j$(nproc) \
    && make install DESTDIR=/out \
    && rm -rf /tmp/*


# autoconf and friends - necessary for building some third-party deps
# from source, not for Couchbase.
FROM base-compile AS autoconf-compile
LABEL imagename=autoconf-compile

ARG AUTOCONF_VER
ARG AUTOMAKE_VER
ARG LIBTOOL_VER
RUN yum install -y --setopt=skip_missing_names_on_install=False --setopt=keepcache=0 perl-Data-Dumper m4
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
WORKDIR /tmp/python
RUN set -x \
    && yum install -y --setopt=skip_missing_names_on_install=False sqlite-devel zlib-devel \
    && curl -Lf https://www.python.org/ftp/python/${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}/Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}.tgz -o - \
        | tar xz --strip-components=1 -C /tmp/python \
    && ./configure --enable-shared --enable-loadable-sqlite-extensions --enable-optimizations --prefix=/usr/local \
    &&  make -j install \
    && curl -f https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/python.conf \
    && ldconfig \
    && /usr/local/bin/python3 /tmp/get-pip.py \
    && cd /tmp \
    && git clone https://github.com/pyinstaller/pyinstaller/ \
    && cd pyinstaller/bootloader \
    && /usr/local/bin/python3 ./waf all


# Git
FROM base-compile AS git-compile
LABEL imagename=git-compile

ARG GIT_VER
RUN mkdir /tmp/git
RUN yum install -y --setopt=skip_missing_names_on_install=False curl-devel expat-devel gettext-devel perl-devel
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

FROM centos:centos7.9.2009
LABEL maintainer="build-team@couchbase.com"

ARG BUILDARCH \
    CLANG_9_VER \
    CLANG_15_VER \
    GCC_VER \
    GCC_12_VER

USER root

# tini, to avoid zombie issues when running with Swarm jar
ARG TINI_VER
ADD https://github.com/krallin/tini/releases/download/v${TINI_VER}/tini-${BUILDARCH} /tini
RUN chmod +x /tini

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repositories
RUN set -x \
    && yum install -y epel-release \
    && yum install --setopt=skip_missing_names_on_install=False --setopt=keepcache=0 -y \
                binutils \
                ed \
                glib2-devel \
                glibc-devel \
                java-11-openjdk-headless \
                libarchive \
                libyaml \
                m4 \
                make \
                man \
                ninja-build \
                ncurses-devel \
                openssh-clients \
                openssh-server \
                patchelf \
                rpm-build \
                rpm-sign \
                rsync \
                sudo \
                tar \
                unzip \
                which \
    && yum clean all

# Pyenv prereqs - for cbdep test suite
RUN set -x \
    && yum install --setopt=skip_missing_names_on_install=False --setopt=keepcache=0 -y \
                bzip2-devel \
                libffi-devel \
                openssl \
                openssl-devel \
                readline-devel \
                uuid-devel \
                tkinter \
                sqlite-devel \
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

# GCC and clang
COPY --from=gcc_10 /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
COPY --from=gcc_12 /opt/gcc-${GCC_12_VER} /opt/gcc-${GCC_12_VER}
COPY --from=clang9 /opt/clang-9.0.0 /opt/clang-9.0.0
COPY --from=clang15 /opt/clang-${CLANG_15_VER} /opt/clang-${CLANG_15_VER}
RUN for prog in gcc g++; do ln -s /opt/gcc-${GCC_VER}/bin/${prog} /usr/local/bin; done
RUN set -x \
    && ln -s /opt/clang-9.0.0/bin/* /usr/bin
RUN for lib in /opt/gcc-${GCC_VER}/lib64/libstd*; do ln -s ${lib} /usr/local/lib64; done
RUN echo /usr/local/lib64 > /etc/ld.so.conf.d/gcc${GCC_VER}.conf && ldconfig
RUN set -x \
    && echo /opt/gcc-${GCC_VER}/lib64 > /etc/ld.so.conf.d/gcc${GCC_VER}.conf \
    && echo /opt/gcc-${GCC_12_VER}/lib64 > /etc/ld.so.conf.d/gcc${GCC_12_VER}.conf \
    && ldconfig

# Autoconf and friends
COPY --from=autoconf-compile /usr/local/ /usr/local/

# * CMake (from cmake.org)
ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl -Lf https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-$(uname -m).sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# repo
RUN set -x \
    && curl -Lf https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# pixz
COPY --from=pixz-compile /out/usr/local/ /usr/local/

# Git
COPY --from=git-compile /usr/local/ /usr/local/

# Python 3 & pip
COPY --from=python-compile /usr/local/ /usr/local/
RUN set -x \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/python.conf \
    && ldconfig

# Ruby
COPY --from=ruby-compile /usr/local/ /usr/local/

# Ccache
COPY --from=ccache-compile /usr/local/ /usr/local/

# Asciidoctor
ARG ASCIIDOCTOR_VER
RUN gem install asciidoctor -v ${ASCIIDOCTOR_VER}

# yq
ARG YQ_VER
RUN set -x \
    && curl -L --fail -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_${BUILDARCH} \
    && chmod a+x /usr/local/bin/yq

# Perl modules
RUN yum install -y  --setopt=skip_missing_names_on_install=False --setopt=keepcache=0 \
        perl-Data-Dumper \
        perl-Digest-SHA \
        perl-Digest-MD5 \
        perl-IPC-Cmd \
    && yum clean all

# JNLP agent (for use in EC2 agents)
ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar
ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

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
RUN set -x \
    && curl -Lf https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_VER}.tgz \
       | tar xz --strip-components=1 -C /usr/local/bin \
    && for gid in {990..997}; do groupadd -g ${gid} docker${gid}; usermod -a -G docker${gid} couchbase; done;
RUN usermod -a -G 999 couchbase

# Need to create some directories so that the swarm stackfile can mount
# on top of them without messing up permisions / ownership.
RUN mkdir -p /home/couchbase/jenkins/workspace /home/couchbase/.cbdepscache /home/couchbase/.cbdepcache/ /home/couchbase/.ccache \
    && chown -R couchbase:couchbase /home/couchbase

COPY bashrc /root/.bashrc
COPY bashrc /home/couchbase/.bashrc

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

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
