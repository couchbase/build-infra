# Docker container for Centos 7

# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
FROM couchbasebuild/centos-7-gcc:${GCC_VER} AS gcc

# This is the actual build agent base image
FROM centos:7.2.1511
LABEL maintainer="build-team@couchbase.com"

# Set LANG
ENV LANG=en_US.UTF-8

USER root

# Work around odd RPM database problems - some from https://github.com/moby/moby/issues/10180
RUN yum clean all && rpm --rebuilddb && yum install -y yum-plugin-ovl deltarpm && yum clean all

# Jenkins Swarm jar
RUN yum install -y java-1.8.0-openjdk-headless curl && \
    yum clean all

ARG SWARM_CLIENT_VER
RUN curl --fail \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VER}/swarm-client-${SWARM_CLIENT_VER}.jar \
    -o /usr/local/lib/swarm-client.jar

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
                numactl-devel \
                openssh-clients \
                openssh-server \
                openssl-devel-1.0.1e \
                python-devel \
                redhat-lsb-core \
                rpm-build \
                rsync \
                ruby rubygems rubygem-rake \
                sqlite-devel \
                sudo \
                tar \
                unzip \
                which && \
    ln -s /usr/bin/python2.7 /usr/bin/python2.6 \
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

COPY build/swarm*.properties /

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
# Historic gcc 7.3.0
COPY --from=couchbasebuild/centos-7-gcc:7.3.0 /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# Install third-party build dependencies
RUN yum install -y --setopt=keepcache=0 perl-Data-Dumper && yum clean all

# Install autoconf and friends - necessary for building some third-party deps
# from source, not for Couchbase.
ARG AUTOCONF_VER
ARG AUTOMAKE_VER
ARG LIBTOOL_VER
RUN mkdir /tmp/deploy && \
    curl -L http://ftpmirror.gnu.org/autoconf/autoconf-${AUTOCONF_VER}.tar.gz -o /tmp/deploy/autoconf-${AUTOCONF_VER}.tar.gz && \
    cd /tmp/deploy && tar -xzf autoconf-${AUTOCONF_VER}.tar.gz && \
    cd autoconf-${AUTOCONF_VER} && ./configure --prefix=/usr/local && make -j8 && make install && \
    curl -L http://ftpmirror.gnu.org/automake/automake-${AUTOMAKE_VER}.tar.gz -o /tmp/deploy/automake-${AUTOMAKE_VER}.tar.gz && \
    cd /tmp/deploy && tar -xzf automake-${AUTOMAKE_VER}.tar.gz && \
    cd automake-${AUTOMAKE_VER} && ./configure --prefix=/usr/local && make && make install && \
    curl -L http://ftpmirror.gnu.org/libtool/libtool-${LIBTOOL_VER}.tar.gz -o /tmp/deploy/libtool-${LIBTOOL_VER}.tar.gz && \
    cd /tmp/deploy && tar -xzf libtool-${LIBTOOL_VER}.tar.gz && \
    cd libtool-${LIBTOOL_VER} && ./configure --prefix=/usr/local && make -j8 && make install && \
    cd /tmp && rm -rf /tmp/deploy

# * CMake (from cmake.org)
ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# * ccache (from source)
ARG CCACHE_VER
RUN mkdir /tmp/deploy && \
    curl -L https://www.samba.org/ftp/ccache/ccache-${CCACHE_VER}.tar.bz2 -o /tmp/deploy/ccache.tar.bz2 && \
    cd /tmp/deploy && tar -xjf ccache.tar.bz2 && \
    cd ccache-${CCACHE_VER} && ./configure --prefix=/usr/local && make -j8 && make install && \
    rm -fr /tmp/deploy

# * repo
RUN set -x \
    && curl --fail https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# * Install cbdep
RUN curl https://packages.couchbase.com/cbdep/0.9.18/cbdep-0.9.18-linux -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

# * Install miniconda3
# One of the benefits is: repo tool requires python 3.5+; the OS comes with python2.  miniconda3 is a flexible way
# of installing python on a system
RUN cbdep install -d /home/couchbase miniconda3-py39 4.9.2 && \
    chown -R couchbase:couchbase /home/couchbase/miniconda3-4.9.2 \
    && /home/couchbase/miniconda3-4.9.2/bin/conda clean --all --force-pkgs-dirs -y

# Still need paramiko in python2 for testrunner (necessary at least for simple-test,
# which runs in the build image rather than the full CV image)
RUN sudo yum install -y epel-release && sudo yum install -y python-pip && \
    pip install --upgrade "pip < 21.0" && \
    pip install paramiko && \
    yum clean all

# Git
ARG GIT_VER
RUN set -x \
    && yum install -y curl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel \
    && cd /usr/src \
    && curl -LO https://www.kernel.org/pub/software/scm/git/git-${GIT_VER}.tar.gz \
    && tar xzf git-${GIT_VER}.tar.gz \
    && rm -f git-${GIT_VER}.tar.gz \
    && cd git-${GIT_VER} \
    && make prefix=/usr/src all \
    && make prefix=/usr/local install \
    && echo "export PATH=$PATH:/usr/local/bin" >> /etc/bashrc \
    && rm -rf /usr/src/git-${GIT_VER} \
    && yum clean all

# Python 3 & pip
ARG PYTHON3_MAJOR
ARG PYTHON3_MINOR
ARG PYTHON3_PATCH
RUN set -x \
    && yum groupinstall -y "Development Tools" \
    && yum install -y openssl-devel libffi-devel bzip2-devel \
    && cd /usr/src \
    && curl -LO --fail https://www.python.org/ftp/python/${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}/Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}.tgz \
    && tar xvf Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}.tgz \
    && rm -f Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH}.tgz \
    && cd Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH} \
    && ./configure --enable-optimizations \
    && make altinstall \
    && update-alternatives --install /usr/local/bin/python3 python3 /usr/local/bin/python${PYTHON3_MAJOR}.${PYTHON3_MINOR} 1 \
    && curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && /usr/local/bin/python3 /tmp/get-pip.py \
    && rm -rf /tmp/get-pip.py /usr/src/Python-${PYTHON3_MAJOR}.${PYTHON3_MINOR}.${PYTHON3_PATCH} \
    && yum clean all

# JNLP agent
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | bash
RUN yum install -y git-lfs && yum clean all

ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Fix locale
RUN set -x \
    && sed -i "s/^override_install_langs=/#override_install_langs=/" /etc/yum.conf \
    && yum reinstall -y glibc-common \
    && yum clean all

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
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
