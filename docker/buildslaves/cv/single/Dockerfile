# Docker container for Single Linux

FROM couchbasebuild/server-linux-build:20230607
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

# # Code coverage requires gcovr to convert from gcov to XML files consumable by Jenkins.
# # Also, if we eventually remove paramiko from the main buildslave image, we could add
# # it back here for CV.
RUN set -x \
    && yum install -y python2-pip \
    && python2 -m pip install MarkupSafe==1.1.1 \
    && python2 -m pip install jinja2==2.11.3 \
    && python2 -m pip install gcovr==4.2

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
RUN set -x \
        && yum install -y aspell \
        && yum clean all

# Install xmlsec1 binary - required by python library for testing pySaml2
RUN set -x \
        && yum install -y xmlsec1 xmlsec1-openssl \
        && yum clean all

# Add startup hook to enable buildx
COPY build/buildx.sh /usr/sbin/couchhook.d/

# Enable additional hook for ccache
COPY build/cv-hook.sh /usr/sbin/couchhook.d/

# CV stuff (specifically alldependencies.py) still needs python2 :(
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 200

# Create clang++-9 symlink
RUN ln -s $(which clang++) $(which clang++)-9

# Enable .gitconfig so repo doesn't get whiny
COPY build/gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Avoid having to rebuild image chain for simple start script modifications
COPY ./build/couchbuilder_start.sh /usr/sbin/
COPY ./build/healthcheck.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}

RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" >> /home/couchbase/.ssh/environment
