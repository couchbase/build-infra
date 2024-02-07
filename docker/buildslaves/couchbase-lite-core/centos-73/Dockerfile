# Docker container for Centos 7.3

# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
FROM couchbasebuild/centos-7-gcc:${GCC_VER} AS gcc

FROM centos:7.3.1611
LABEL maintainer="build-team@couchbase.com"

USER root
RUN yum clean all && yum swap -y fakesystemd systemd

RUN yum install --setopt=keepcache=0 -y \
    deltarpm \
    ca-certificates \
    git \
    sudo \
    which \
    yum-plugin-ovl

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
    chmod 440 /etc/sudoers.d/wheel_group

# Swarm client jar - only needed until CBD-4101 is resolved
RUN curl --fail \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.25/swarm-client-3.25.jar \
    -o /usr/local/lib/swarm-client.jar

# * repo
RUN curl --fail https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# FPM packaging tool
# Need to lock some versions because newer ones require higher versions of ruby
RUN yum install -y ruby-devel gcc make rpm-build rubygems

RUN gem install ffi:1.12.2 && \
    gem install fpm:1.11.0

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
# Historic gcc 7.3.0
COPY --from=couchbasebuild/centos-7-gcc:7.3.0 /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
    mv /tmp/ld.so.conf /etc && ldconfig

# Install Couchbase Lite Core toolchain requirements,
# including updated binutils for vector search build
RUN yum install -y --setopt=keepcache=0 tar openssl-devel make redhat-lsb-core wget unzip zip java-11-openjdk-devel binutils

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl --fail -L https://www.samba.org/ftp/ccache/ccache-3.3.4.tar.xz -o /tmp/deploy/ccache.tar.xz && \
    cd /tmp/deploy && tar -xf ccache.tar.xz && \
    cd ccache-3.3.4 && ./configure --prefix=/usr/local && make -j8 && make install && \
    rm -fr /tmp/deploy

# * CMake (from cmake.org)
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v3.20/cmake-3.20.1-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# fr_FR locale for LiteCore testing
RUN sudo localedef -v -c -i fr_FR -f UTF-8 fr_FR || true

# Add "shasum" command (use by cbl-java build, at least)
RUN yum install -y --setopt=keepcache=0 perl-Digest-SHA

# Add cbdep tool (used by cbl-java build, at least)
RUN curl --fail http://downloads.build.couchbase.com/cbdep/cbdep.linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

# Python 3 & pip
RUN set -x \
    && yum groupinstall -y "Development Tools" \
    && yum install -y openssl-devel libffi-devel bzip2-devel \
    && cd /usr/src \
    && curl --fail https://www.python.org/ftp/python/3.7.7/Python-3.7.7.tgz | tar xzf - \
    && cd Python-3.7.7 \
    && ./configure --enable-optimizations \
    && make altinstall \
    && update-alternatives --install /usr/local/bin/python3 python3 /usr/local/bin/python3.7 1 \
    && curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && /usr/local/bin/python3 /tmp/get-pip.py \
    && rm -rf /tmp/get-pip.py /usr/src/Python-3.7.7 \
    && yum clean all

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
