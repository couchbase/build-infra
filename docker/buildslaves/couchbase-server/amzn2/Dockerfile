# Docker container for Amazon 2.0
# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
ARG ARCH
FROM couchbasebuild/amzn-2-gcc:${GCC_VER}-${ARCH} AS gcc
ARG ARCH
FROM couchbasebuild/amzn-2-gcc:7.3.0-${ARCH} AS gcc-legacy

# This is the actual build agent base image
FROM amazonlinux:2
LABEL maintainer="build-team@couchbase.com"

USER root
RUN yum -y update; yum clean all

# Jenkins Swarm jar
RUN yum install -y java-1.8.0-openjdk-headless curl && \
    yum clean all

ARG SWARM_CLIENT_VER
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VER}/swarm-client-${SWARM_CLIENT_VER}.jar \
    -o /usr/local/lib/swarm-client.jar

### Install Couchbase build dependencies ######################################
# * Packages from the base Amazon Linux 2 repositories
RUN yum install --setopt=keepcache=0 -y \
                deltarpm \
                ed \
                git \
                glibc-devel \
                gzip \
                make \
                man \
                ncurses-devel \
                ninja-build \
                numactl-devel \
                openssh-clients \
                openssh-server \
                openssl \
                openssl-devel \
                python-devel \
                redhat-lsb-core \
                rpm-build \
                rsync \
                ruby rubygems rubygem-rake \
                sqlite-devel \
                sudo \
                tar \
                unzip \
                vim \
                wget \
                which \
                xz \
    && yum clean all \
    && ln -s /usr/bin/python2.7 /usr/bin/python2.6

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

# Install third-party build dependencies
RUN yum install -y --setopt=keepcache=0 perl-Data-Dumper && yum clean all

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}

# Historic gcc 7.3.0
COPY --from=gcc-legacy /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# Since there's no compiler other than gcc 10 in the aarch64 image, put
# that one on the default PATH. Also, for whatever reasons, pyinstaller
# requires the "strip" binary to be in the same directory as the compiler.
RUN if [ "$(uname -m)" == "aarch64" ]; then \
      ln -s "$(which strip)" /opt/gcc-${GCC_VER}/bin; \
      for prog in gcc g++ strip; do \
        ln -s /opt/gcc-${GCC_VER}/bin/${prog} /usr/local/bin; \
      done; \
    fi

# Install autoconf and friends - necessary for building some third-party deps
# from source, not for Couchbase.
ARG AUTOCONF_VER
ARG AUTOMAKE_VER
ARG LIBTOOL_VER
RUN set -x \
    && mkdir /tmp/deploy \
    && curl -L http://ftpmirror.gnu.org/autoconf/autoconf-${AUTOCONF_VER}.tar.gz -o /tmp/deploy/autoconf-${AUTOCONF_VER}.tar.gz \
    && cd /tmp/deploy \
    && tar -xzf autoconf-${AUTOCONF_VER}.tar.gz \
    && cd autoconf-${AUTOCONF_VER} \
    && ./configure --prefix=/usr/local \
    && make -j8 \
    && make install

RUN set -x \
    && curl -L http://ftpmirror.gnu.org/automake/automake-${AUTOMAKE_VER}.tar.gz -o /tmp/deploy/automake-${AUTOMAKE_VER}.tar.gz \
    && cd /tmp/deploy \
    && tar -xzf automake-${AUTOMAKE_VER}.tar.gz \
    && cd automake-${AUTOMAKE_VER} \
    && ./configure --prefix=/usr/local \
    && make \
    && make install

RUN set -x \
    && curl -L http://ftpmirror.gnu.org/libtool/libtool-${LIBTOOL_VER}.tar.gz -o /tmp/deploy/libtool-${LIBTOOL_VER}.tar.gz \
    && cd /tmp/deploy \
    && tar -xzf libtool-${LIBTOOL_VER}.tar.gz \
    && ls /opt/gcc-${GCC_VER}/bin \
    && cd libtool-${LIBTOOL_VER} \
    && ./configure --prefix=/usr/local && make -j8 \
    && make install \
    && cd /tmp \
    && rm -rf /tmp/deploy

# * CMake 3 (from cmake.org)
ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-$(uname -m).sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# * ccache (from source)
ARG CCACHE_VER
RUN set -x \
    && mkdir /tmp/deploy && \
    curl -L https://www.samba.org/ftp/ccache/ccache-${CCACHE_VER}.tar.bz2 -o /tmp/deploy/ccache.tar.bz2 && \
    cd /tmp/deploy && tar -xjf ccache.tar.bz2 && \
    cd ccache-${CCACHE_VER} && ./configure --prefix=/usr/local && make -j8 && make install && \
    rm -fr /tmp/deploy

# * repo
RUN curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# * Install cbdep
RUN curl https://packages.couchbase.com/cbdep/cbdep-linux-$(uname -m) -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

# * Install miniconda3
# One of the benefits is: repo tool requires python 3.5+; the OS comes with python2.  miniconda3 is a flexible way
# of installing python on a system
RUN set -x \
    && cbdep install -d /opt miniconda3-py39 4.9.2 \
    && chown -R couchbase:couchbase /opt/miniconda3-4.9.2 \
    && ln -sf /opt/miniconda3-4.9.2/bin/python /usr/bin/python3 \
    && rm -rf /root/.cbdepcache \
    && /opt/miniconda3-4.9.2/bin/conda clean --all --force-pkgs-dirs -y


ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Set LANG
ENV LANG=en_US.UTF-8

# disable password auth for ssh
RUN set -x \
    && grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config \
    && sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config \
    || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Expose SSH daemon and run our builder startup script
EXPOSE 22
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
