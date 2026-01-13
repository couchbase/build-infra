# Docker container for Single Linux

FROM couchbasebuild/server-linux-build:20260109
LABEL maintainer="build-team@couchbase.com"

ARG DOCKER_VERSION
ARG VALGRIND_VERSION
ARG JYTHON_VERSION

COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# ENV vars for profile data retrieval
ENV NODE_CLASS=cv
ENV NODE_PRODUCT=couchbase-server

USER root

WORKDIR /tmp

RUN set -x \
    && yum install -y wget \
    && yum clean all

# Needed to ensure LANG is set correctly when ssh'ing into agent
COPY build/ssh_environment /home/couchbase/.ssh/environment
RUN set -x \
        && sed -ri 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config \
        && chown -R couchbase:couchbase /home/couchbase/.ssh

# Valgrind needed for leak checking as part of unit tests. Note: It requires
# libc debug symbols (glibc-debuginfo) to ensure it can locate the address of strlen().
RUN set -x \
        && wget -qO- ftp://sourceware.org/pub/valgrind/valgrind-${VALGRIND_VERSION}.tar.bz2 | tar -xjf - --strip-components=1 \
        && ./configure --prefix=/usr/local && make -j$(nproc) && make install \
        && debuginfo-install -y glibc \
        && rm -rf /tmp/* && ccache --clear && yum clean all

# Install GDB - needed for detecting what program created a core file
# & extracting the set of shared libraries.
RUN set -x \
        && yum install -y gdb \
        && yum clean all

# Install Lua - Needed for lua-based tests in Couchstore
RUN set -x \
        && yum install -y lua lua-devel \
        && yum clean all

# Install chrpath - used to fix libtsan.so's dynamic linker
RUN set -x \
        && yum install -y chrpath \
        && yum clean all

# Install Jython
RUN set -x \
        && curl -sLO https://repo1.maven.org/maven2/org/python/jython-installer/${JYTHON_VERSION}/jython-installer-${JYTHON_VERSION}.jar \
        && mkdir /opt/jython && chown couchbase:couchbase /opt/jython \
        && su couchbase -c "java -jar jython-installer-${JYTHON_VERSION}.jar -s -t minimum -d /opt/jython" \
        && ln -s /opt/jython/bin/jython /usr/local/bin/ \
        && rm -rf /tmp/*

# Install aspell
ARG ASPELL_DICT_VERSION
RUN set -x \
        && mkdir /tmp/aspell \
        && cd /tmp/aspell \
        && yum install -y aspell \
        && curl -L -o /tmp/aspell-dict.tar.bz2 https://ftp.gnu.org/gnu/aspell/dict/en/aspell6-en-${ASPELL_DICT_VERSION}.tar.bz2 \
        && tar xf /tmp/aspell-dict.tar.bz2 --strip-components=1 \
        && ./configure && make && make install \
        && rm -rf /tmp/aspell* \
        && yum clean all

# Install xmlsec1 binary - required by python library for testing pySaml2
RUN set -x \
        && yum install -y xmlsec1 xmlsec1-openssl \
        && yum clean all

# Testrunner python modules
RUN pip3 install sgmllib3k==1.0.0 paramiko==2.7.1 httplib2==0.17.1 pyyaml==5.3.1 \
         beautifulsoup4==4.8.2 Geohash==1.0 python-geohash==0.8.5 deepdiff==4.3.2 \
         pyes==0.99.6 pytz==2019.3 requests==2.23.0 jsonpickle==1.3 \
         docker==4.2.0 decorator==4.4.2

# GDB 8
RUN set -x \
    && yum install -y texinfo \
    && yum clean all \
    && curl -Lf -o /tmp/gdb.tgz https://ftpmirror.gnu.org/gnu/gdb/gdb-8.1.1.tar.gz \
    && mkdir /tmp/gdb \
    && cd /tmp/gdb \
    && tar xf /tmp/gdb.tgz --strip-components=1 \
    && ./configure --prefix=/usr \
    && make && make install \
    && rm -rf /tmp/gdb*

RUN set -x \
    && pip install gcovr

# lsof and netstat for debugging purposes
RUN yum install -y lsof net-tools && yum clean all

# Add startup hook to enable buildx
COPY build/buildx.sh /usr/sbin/couchhook.d/

# Enable additional hook for ccache
COPY build/cv-hook.sh /usr/sbin/couchhook.d/

# CV stuff (specifically alldependencies.py) still needs python2 :(
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 200

# Enable .gitconfig so repo doesn't get whiny
COPY build/gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Avoid having to rebuild image chain for simple start script modifications
COPY ./build/couchbuilder_start.sh /usr/sbin/
COPY ./build/healthcheck.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}

RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" >> /home/couchbase/.ssh/environment
