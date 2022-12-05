# Docker container for SUSE 15, based on openSUSE LEAP

# This has to be first - define the GCC version to use and
# the image to pull it from
ARG GCC_VER
FROM couchbasebuild/suse-15-gcc:${GCC_VER} AS gcc

# This is the actual build agent base image
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
ARG TINI_VER
ADD https://github.com/krallin/tini/releases/download/v${TINI_VER}/tini /tini
RUN chmod +x /tini

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

ARG JRE_MAJOR
ARG JRE_VERSION
ARG JRE_BUILD
RUN set -x \
    && ARCH=$(uname -m | sed -e 's/86_//') \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -Lf https://github.com/adoptium/temurin${JRE_MAJOR}-binaries/releases/download/jdk-${JRE_VERSION}%2B${JRE_BUILD}/OpenJDK${JRE_MAJOR}U-jre_${ARCH}_linux_hotspot_${JRE_VERSION}_${JRE_BUILD}.tar.gz -o openjre.tar.gz \
    && cd /usr/local \
    && tar xvzf /tmp/deploy/openjre.tar.gz \
    && ln -s jdk* java \
    && for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done \
    && rm -rf /tmp/deploy

# * CMake (from cmake.org)
ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl -f https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
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
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
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

# GCC - need to redundantly declare GCC_ARG here
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY --from=gcc /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
# Historic gcc 7.3.0
COPY --from=couchbasebuild/suse-15-gcc:7.3.0 /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

RUN set -x \
        && update-alternatives --install /usr/bin/gcc gcc /usr/local/bin/gcc 100 \
        && update-alternatives --install /usr/bin/g++ g++ /usr/local/bin/g++ 100

ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Install asciidoctor
ARG ASCIIDOCTOR_VER
RUN set -x \
    && gem install asciidoctor -v ${ASCIIDOCTOR_VER} \
    && ln -s /usr/bin/asciidoctor.ruby2.5 /usr/local/bin/asciidoctor

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

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
