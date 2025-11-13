# syntax=docker/dockerfile:1.3
# Docker container for Single Linux build. Currently based on
# Centos 7 as it has the oldest glibc of the distros we support.

ARG GCC_10_VER
ARG GCC_10_TAG
ARG GCC_13_VER
ARG GCC_13_TAG
ARG CLANG_9_VER
ARG CLANG_9_TAG
ARG CLANG_15_VER
ARG CLANG_15_TAG
ARG CLANG_18_VER
ARG CLANG_18_TAG
FROM couchbasebuild/single-gcc:${GCC_10_VER}-${GCC_10_TAG} AS gcc_10
FROM couchbasebuild/single-gcc:${GCC_13_VER}-${GCC_13_TAG} AS gcc_13
FROM couchbasebuild/single-clang:${CLANG_9_VER}-${CLANG_9_TAG} AS clang9
FROM couchbasebuild/single-clang:${CLANG_15_VER}-${CLANG_15_TAG} AS clang15
FROM couchbasebuild/single-clang:${CLANG_18_VER}-${CLANG_18_TAG} AS clang18

# Base image
FROM centos:centos7.9.2009 AS base

# Use vault for package installation - CentOS 7 is now EOL, so the original
# mirrors are no longer available
RUN sed -i -e '/^mirrorlist/d;/^#baseurl=/{s,^#,,;s,/mirror,/vault,;}' /etc/yum.repos.d/CentOS*.repo

# Start of compile-only stages

# First a base compile image that has some recurring dependencies
FROM base AS base-compile
ARG GCC_13_VER
ARG BINUTILS_VER
LABEL imagename=base-compile

COPY --from=gcc_13 /opt/gcc-${GCC_13_VER} /opt/gcc-${GCC_13_VER}
COPY --from=gcc_13 /opt/binutils-${BINUTILS_VER} /opt/binutils-${BINUTILS_VER}

ENV PATH=/opt/gcc-${GCC_13_VER}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN ulimit -n 1024 && yum install -y --setopt=skip_missing_names_on_install=False curl deltarpm sudo
RUN ulimit -n 1024 && yum groupinstall -y "Development Tools"
RUN ulimit -n 1024 && yum install -y --setopt=skip_missing_names_on_install=False bzip2-devel libarchive-devel xz-devel libffi-devel ncurses-devel openssl-devel openssl-devel readline-devel zlib-devel

# sed - the stock version doesn't support extended expressions
FROM base-compile AS sed-compile
WORKDIR /tmp
ARG SED_VERSION=4.9
ARG SED_SHA=6aac9b2dbafcd5b7a67a8a9bcb8036c3
ADD https://ftpmirror.gnu.org/gnu/sed/sed-${SED_VERSION}.tar.xz /tmp/sed.tar.xz
RUN set -x \
    && echo ${SED_SHA} /tmp/sed.tar.xz | md5sum -c - \
    && mkdir /tmp/sed && cd /tmp/sed \
    && tar xf /tmp/sed.tar.xz --strip-components=1 \
    && ./configure --prefix=/usr/local \
    && make -j$(nproc) \
    && make install DESTDIR=/out \
    && rm -rf /tmp/*

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
RUN ulimit -n 1024 && yum install -y --setopt=skip_missing_names_on_install=False --setopt=keepcache=0 perl-Data-Dumper m4
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
ARG RUBY_MAJOR
ARG RUBY_MINOR
ARG RUBY_PATCH
ARG RUBY_INSTALL_VER="${RUBY_INSTALL_MAJOR}.${RUBY_INSTALL_MINOR}.${RUBY_INSTALL_PATCH}"
RUN mkdir /tmp/ruby-install
RUN curl -Lf /tmp/ruby-install-${RUBY_INSTALL_VER}.tar.gz https://github.com/postmodern/ruby-install/archive/v${RUBY_INSTALL_VER}.tar.gz -o - \
        | tar xz --strip-components=1 -C /tmp/ruby-install
WORKDIR /tmp/ruby-install
RUN sudo make -j8 install

# Ruby itself
RUN ulimit -n 1024 && ruby-install -c --prefix /usr/local -j8 ${RUBY_MAJOR}.${RUBY_MINOR}.${RUBY_PATCH} && ls -l /usr/local/bin/ruby

# OpenSSL
FROM base-compile AS openssl-compile
ARG OPENSSL_VER
RUN ulimit -n 1024 && yum install -y perl-IPC-Cmd
WORKDIR /tmp/openssl-1.1.1${OPENSSL_VER}
ADD https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1${OPENSSL_VER}/openssl-1.1.1${OPENSSL_VER}.tar.gz /tmp
RUN set -x \
    && tar xf /tmp/openssl-1.1.1${OPENSSL_VER}.tar.gz --strip-components=1 \
    && ./config --prefix=/usr/local --libdir=lib --openssldir=/etc/pki/tls shared \
    && make -j8 \
    && make install \
    && rm -rf /tmp/openssl*

# Python
FROM openssl-compile AS python-compile
LABEL imagename=python-compile

ARG OPENSSL_VER
ARG PYTHON3_MAJOR
ARG PYTHON3_MINOR
ARG PYTHON3_PATCH
WORKDIR /tmp/python
RUN set -x \
    && ulimit -n 1024 \
    && yum install -y --setopt=skip_missing_names_on_install=False \
        bzip2-devel \
        libpcap-devel \
        sqlite-devel \
        tk-devel \
        xz-devel

ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"
RUN set -x \
    && curl -Lf https://www.python.org/ftp/python/${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}/Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}.tgz -o - \
        | tar xz --strip-components=1 -C /tmp/python \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/python-openssl.conf \
    && ldconfig \
    && ./configure \
        --enable-shared \
        --enable-loadable-sqlite-extensions \
        --enable-optimizations \
        --prefix=/usr/local \
        --with-ssl-default-suites=openssl \
        --with-openssl=/usr/local \
    && make -j8 install \
    && ldconfig \
    && curl -f https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && /usr/local/bin/python3 /tmp/get-pip.py

# Ccache
FROM base-compile AS ccache-compile
LABEL imagename=ccache-compile

ARG CCACHE_VER
RUN mkdir /tmp/ccache
RUN curl -Lf https://www.samba.org/ftp/ccache/ccache-${CCACHE_VER}.tar.bz2 -o - | tar xj --strip-components=1 -C /tmp/ccache
WORKDIR /tmp/ccache
RUN ./configure --prefix=/usr/local && make -j$(nproc) && make install

# -----------------------------------------
# This is the actual build agent base image
# -----------------------------------------

FROM base
LABEL maintainer="build-team@couchbase.com"

ARG TARGETARCH \
    BINUTILS_VER \
    CLANG_9_VER \
    CLANG_15_VER \
    CLANG_18_VER \
    GCC_10_VER \
    GCC_13_VER

USER root

ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig:/usr/share/pkgconfig"

# Buildx
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# tini, to avoid zombie issues when running with Swarm jar
ARG TINI_VER
ADD https://github.com/krallin/tini/releases/download/v${TINI_VER}/tini-${TARGETARCH} /tini
RUN chmod +x /tini

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repositories
RUN set -x \
    && ulimit -n 1024 \
    && yum install -y epel-release \
    && yum install --setopt=skip_missing_names_on_install=False --setopt=keepcache=0 -y \
                awscli \
                binutils \
                chrpath \
                ed \
                glib2-devel \
                glibc-devel \
                libarchive \
                libyaml \
                m4 \
                make \
                man \
                ninja-build \
                ncurses-devel \
                openssl-devel \
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
                xfsprogs-devel \
    && ln -s $(which ninja-build) /usr/local/bin/ninja \
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
    echo 'Defaults env_keep += "PATH"' >> /etc/sudoers.d/wheel_group && \
    sed -i 's/^Defaults\s\+secure_path.*/# &/' /etc/sudoers && \
    chmod 440 /etc/sudoers.d/wheel_group && \
    usermod -G wheel root

# GCC, binutils and clang
COPY --from=gcc_10 /opt/gcc-${GCC_10_VER} /opt/gcc-${GCC_10_VER}
COPY --from=gcc_13 /opt/gcc-${GCC_13_VER} /opt/gcc-${GCC_13_VER}
COPY --from=gcc_13 /opt/binutils-${BINUTILS_VER} /opt/binutils-${BINUTILS_VER}
COPY --from=clang9 /opt/clang-9.0.0 /opt/clang-9.0.0
COPY --from=clang15 /opt/clang-${CLANG_15_VER} /opt/clang-${CLANG_15_VER}
COPY --from=clang18 /opt/clang-${CLANG_18_VER} /opt/clang-${CLANG_18_VER}
RUN for prog in gcc g++; do ln -s /opt/gcc-${GCC_10_VER}/bin/${prog} /usr/local/bin; done
RUN set -x \
    && ln -s /opt/clang-${CLANG_9_VER}/bin/* /usr/local/bin \
    && ln -s /opt/binutils-${BINUTILS_VER}/bin/* /usr/local/bin \
    && rm -rf /opt/gcc-${GCC_10_VER}/lib64/libstdc* \
    && cp /opt/gcc-${GCC_13_VER}/lib64/libstdc* /opt/gcc-${GCC_10_VER}/lib64
RUN for lib in /opt/gcc-${GCC_10_VER}/lib64/libstd*; do ln -s ${lib} /usr/local/lib64; done
RUN echo /usr/local/lib64 > /etc/ld.so.conf.d/gcc${GCC_10_VER}.conf && ldconfig
RUN set -x \
    && echo /opt/gcc-${GCC_10_VER}/lib64 > /etc/ld.so.conf.d/gcc${GCC_10_VER}.conf \
    && echo /opt/gcc-${GCC_13_VER}/lib64 > /etc/ld.so.conf.d/gcc${GCC_13_VER}.conf \
    && ldconfig

# clang is built against a specific GCC root. If you upgrade gcc, you must
# rebuild any associated clang version
RUN for clang in ${CLANG_9_VER} ${CLANG_15_VER} ${CLANG_18_VER}; do \
      if ! /opt/clang-$clang/bin/clang --version; then \
        echo "clang-$clang is broken, please ensure you have rebuilt it if you are upgrading gcc"; \
        exit 1; \
      fi; \
    done

# Git (needs to be built with newer gcc than is available in base builder)
ARG GIT_VER
RUN mkdir /tmp/git
RUN ulimit -n 1024 && yum install -y --setopt=skip_missing_names_on_install=False curl-devel expat-devel gettext-devel perl-devel && yum clean all
RUN set -x \
    && curl -Lf https://www.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.gz -o - \
        | tar xz --strip-components=1 -C /tmp/git \
    && cd /tmp/git \
    && PATH=/opt/gcc-${GCC_13_VER}/bin:$PATH make -j4 prefix=/usr/local install \
    && rm -rf /tmp/git

# Install the latest gdb and symlink in /usr/local/bin
ARG GDB_VER
RUN set -x \
    && ulimit -n 1024 \
    && yum install -y texinfo gmp-devel mpfr-devel && yum clean all \
    && mkdir -p /opt/gdb-${GDB_VER} /tmp/gdb \
    && cd /tmp/gdb \
    && curl -Lf https://ftpmirror.gnu.org/gnu/gdb/gdb-${GDB_VER}.tar.gz -o - \
        | tar xz --strip-components=1 \
    && ./configure --prefix=/opt/gdb-${GDB_VER} \
    && make -j$(nproc) \
    && make install \
    && ln -sf /opt/gdb-${GDB_VER}/bin/gdb /usr/local/bin/gdb \
    && rm -rf /tmp/gdb

# Perl modules
RUN ulimit -n 1024 && \
    yum install -y  --setopt=skip_missing_names_on_install=False --setopt=keepcache=0 \
        perl-Data-Dumper \
        perl-Digest-SHA \
        perl-Digest-MD5 \
        perl-IPC-Cmd \
    && yum clean all

# Installer chroots - these are simple images that rarely change, so
# just pull versioned :latest tags
COPY --from=couchbasebuild/deb-packager:debian11-latest / /opt/deb-chroot
COPY --from=couchbasebuild/rpm-packager:rocky8-latest / /opt/rpm-chroot

# Since the couchbasebuild/xxx-packager images were built directly from
# a Dockerfile, they don't have any /dev/ stuff since Docker generally
# magicks those into existence when a container is started. They can't
# explicitly create them, either, since they already exist during
# "docker build". So, since we're copying them into a non-/ directory
# here, we need to create any such files ourselves. Experimentally, it
# seems like only /dev/null is really important.
RUN mknod -m 666 /opt/deb-chroot/dev/null c 1 3
RUN mknod -m 666 /opt/rpm-chroot/dev/null c 1 3

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
    && sed -i 's/env python$/env python3/' /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# sed
COPY --from=sed-compile /out/usr/local/ /usr/local/

# pixz - still needed for packaging .deb files in 7.x
COPY --from=pixz-compile /out/usr/local/ /usr/local/

# Python 3, OpenSSL 1.1.1, pip
COPY --from=python-compile /usr/local/ /usr/local/
COPY --from=python-compile /etc/pki/tls /etc/pki/tls
RUN set -x \
    && echo "/usr/local/lib" > /etc/ld.so.conf.d/python.conf \
    && ldconfig

# Ruby
COPY --from=ruby-compile /usr/local/ /usr/local/

# Ccache
COPY --from=ccache-compile /usr/local/ /usr/local/

# Asciidoctor
ARG ASCIIDOCTOR_VER
RUN gem install asciidoctor -v ${ASCIIDOCTOR_VER} && rm -rf /root/.gem

# jq and yq
ARG JQ_VER
ARG YQ_VER
RUN set -x \
    && curl -L --fail -o /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-${JQ_VER}/jq-linux-${TARGETARCH} \
    && chmod a+x /usr/local/bin/jq \
    && curl -L --fail -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_${TARGETARCH} \
    && chmod a+x /usr/local/bin/yq

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

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# Our python tool wrappers
RUN curl -Lf https://packages.couchbase.com/patch_via_gerrit/patch_via_gerrit-linux-$(uname -m) -o /usr/local/bin/patch_via_gerrit && \
    chmod a+x /usr/local/bin/patch_via_gerrit
RUN curl -Lf https://packages.couchbase.com/cbdep/cbdep-linux-$(uname -m) -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

# Remember this path for Jenkins agents (see entrypoint script)
RUN echo "/usr/local/bin" >> /etc/path

# Use cbdep to install JVM for Jenkins
ARG JRE_VERSION
ARG JRE_BUILD
RUN cbdep install -d /usr/local openjdk ${JRE_VERSION}+${JRE_BUILD} \
    && ln -s /usr/local/openjdk-${JRE_VERSION}+${JRE_BUILD}/bin/java /usr/local/bin/java \
    && rm -rf /root/.cbdepcache /root/.local

# Docker
ARG DOCKER_VER
RUN set -x \
    && curl -Lf https://download.docker.com/linux/static/stable/$(uname -m)/docker-${DOCKER_VER}.tgz \
       | tar xz --strip-components=1 -C /usr/local/bin \
    && for gid in {990..997}; do groupadd -g ${gid} docker${gid}; usermod -a -G docker${gid} couchbase; done;
RUN usermod -a -G 999 couchbase

# Dev packages required for building pyinstaller tools
RUN ulimit -n 1024 && yum install -y libxml2-devel libxslt-devel && yum clean all

# Strace to help when debugging issues
RUN ulimit -n 1024 && yum install -y strace && yum clean all

# Truncate logfiles
RUN find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# Remove unnecessary files and directories
RUN rm -rf /tmp/* /var/cache/yum

# Need to create some directories so that the swarm stackfile can mount
# on top of them without messing up permissions / ownership.
USER couchbase
RUN mkdir -p /home/couchbase/jenkins/workspace /home/couchbase/.cbdepscache /home/couchbase/.cbdepcache/ /home/couchbase/.ccache

USER root
COPY bashrc /etc/bashrc

ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

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
