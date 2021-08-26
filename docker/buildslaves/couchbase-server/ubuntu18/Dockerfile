# Docker container for Ubuntu 18.04

# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
FROM couchbasebuild/ubuntu-18-gcc:${GCC_VER} AS gcc

# This is the actual build agent base image
FROM ubuntu:18.04
LABEL maintainer="build-team@couchbase.com"

USER root

# Install SSH server and sudo
RUN apt-get update && \
    apt-get install -y openssh-server sudo curl && \
    apt-get clean && \
    mkdir /var/run/sshd

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Jenkins Swarm jar
ARG SWARM_CLIENT_VER
RUN apt-get update && \
    apt-get install -y openjdk-8-jre-headless && \
    apt-get clean
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VER}/swarm-client-${SWARM_CLIENT_VER}.jar \
    -o /usr/local/lib/swarm-client.jar

# tini, to avoid zombie issues when running with Swarm jar
ARG TINI_VER
ADD https://github.com/krallin/tini/releases/download/v${TINI_VER}/tini /tini
RUN chmod +x /tini

# Install Couchbase build dependencies
RUN apt-get update && \
    apt-get install -y \
        ccache \
        debhelper \
        devscripts \
        dh-systemd \
        ed \
        git-core \
        libnuma-dev \
        libsqlite3-dev \
        libssl-dev \
        man \
        ncurses-dev \
        pixz \
        pkg-config \
        python-dev \
        python-pip \
        rake \
        ruby \
        tar \
        zlib1g-dev && \
    apt-get clean && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 100

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
# Historic gcc 7.3.0
COPY --from=couchbasebuild/ubuntu-1804-gcc:7.3.0 /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# Install third-party build dependencies.
RUN apt-get update && \
    apt-get install -y m4 && \
    apt-get clean

ARG AUTOCONF_VER
ARG AUTOMAKE_VER
ARG LIBTOOL_VER
RUN mkdir /tmp/deploy && \
    curl -Lf http://ftpmirror.gnu.org/autoconf/autoconf-${AUTOCONF_VER}.tar.gz -o /tmp/deploy/autoconf-${AUTOCONF_VER}.tar.gz && \
    cd /tmp/deploy && tar -xzf autoconf-${AUTOCONF_VER}.tar.gz && \
    cd autoconf-${AUTOCONF_VER} && ./configure --prefix=/usr/local && make && make install && \
    curl -Lf http://ftpmirror.gnu.org/automake/automake-${AUTOMAKE_VER}.tar.gz -o /tmp/deploy/automake-${AUTOMAKE_VER}.tar.gz && \
    cd /tmp/deploy && tar -xzf automake-${AUTOMAKE_VER}.tar.gz && \
    cd automake-${AUTOMAKE_VER} && ./configure --prefix=/usr/local && make && make install && \
    curl -Lf http://ftpmirror.gnu.org/libtool/libtool-${LIBTOOL_VER}.tar.gz -o /tmp/deploy/libtool-${LIBTOOL_VER}.tar.gz && \
    cd /tmp/deploy && tar -xzf libtool-${LIBTOOL_VER}.tar.gz && \
    cd libtool-${LIBTOOL_VER} && ./configure --prefix=/usr/local && make && make install && \
    cd /tmp && rm -rf /tmp/deploy

RUN echo 'PATH="/usr/lib/ccache:$PATH"' >> /home/couchbase/.profile

ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo && \
    cd /tmp && rm -rf /tmp/deploy

# Python 3-specific stuff for build scripts, mostly for Jira.
# Second "pip3 install" command is for requirements for testrunner/python3.
RUN set -x \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get -y install python3.7 python3.7-dev python3.7-venv libffi-dev \
    && apt-get clean \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.7 1 \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 \
    && rm /usr/local/bin/pip \
    && pip3 install lxml==4.6.1 jwt==1.0.0 pycrypto jira==2.0.0 boto3==1.16.4 pbr==5.5.1 cffi==1.14.3 \
    && pip3 install sgmllib3k==1.0.0 paramiko==2.7.1 httplib2==0.17.1 pyyaml==5.3.1 \
         beautifulsoup4==4.8.2 Geohash==1.0 python-geohash==0.8.5 deepdiff==4.3.2 \
         pyes==0.99.6 pytz==2019.3 requests==2.23.0 jsonpickle==1.3 \
         docker==4.2.0 decorator==4.4.2 \
    && apt-get autoremove --purge -y \
    &&apt-get clean \
    && ccache --clear

# Still need paramiko in python2 for testrunner (necessary at least for simple-test,
# which runs in the build image rather than the full CV image).
# Python 2-specific stuff for build scripts, mostly old build-sanity stuff.
RUN python2 -m pip install paramiko jenkinsapi

#s3cmd for upload script
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y s3cmd  && \
    apt-get clean

# Set 8G ccache limit
USER couchbase
RUN ccache -M 8G
USER root

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8

# Add rsync for pulling config+secrets at startup
RUN set -x \
        && apt update \
        && apt install -y rsync \
        && apt clean

ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Install asciidoc
ARG ASCIIDOCTOR_VER
RUN gem install asciidoctor -v ${ASCIIDOCTOR_VER}

# Set LANG
ENV LANG=en_US.UTF-8

# Set AWS credentials file environmental variable
ENV AWS_SHARED_CREDENTIALS_FILE=/home/couchbase/.ssh/aws-credentials

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Expose SSH daemon and run our builder startup script
EXPOSE 22

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
