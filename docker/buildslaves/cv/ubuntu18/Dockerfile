# Docker container for Ubuntu 18.04

FROM couchbasebuild/server-ubuntu18-clang9-build:20230524
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

# Needed to ensure LANG is set correctly when ssh'ing into agent
COPY ssh_environment /home/couchbase/.ssh/environment
RUN set -x \
        && sed -ri 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config \
        && chown -R couchbase:couchbase /home/couchbase/.ssh

# Install docker static binary for running docker command-line
RUN set -x \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -o docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
    && tar xf docker.tgz \
    && cp -a docker/docker /usr/local/bin \
    && cd /tmp \
    && rm -rf deploy

# Valgrind needed for leak checking as part of unit tests. Note: It requires
# libc debug symbols (libc6-dbg) to ensure it can locate the address of strlen().
RUN set -x \
        && wget -qO- ftp://sourceware.org/pub/valgrind/valgrind-${VALGRIND_VERSION}.tar.bz2 | tar -xjf - --strip-components=1 \
        && ./configure --prefix=/usr/local && make -j8 && make install \
        && apt update && apt install -y libc6-dbg \
        && rm -rf /tmp/* && ccache --clear && apt clean

# Code coverage requires gcovr to convert from gcov to XML files consumable by Jenkins.
# Also, if we eventually remove paramiko from the main buildslave image, we could add
# it back here for CV.
RUN python2 -m pip install gcovr

# Install clang-tools for scan-build for older branches
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb https://apt.llvm.org/bionic llvm-toolchain-bionic-6.0 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-tools-6.0 \
        && apt clean

# Install clang-format from Clang 6.0 - needed for checking if formatting of patch is correct for older branches
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb https://apt.llvm.org/bionic llvm-toolchain-bionic-6.0 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-format-6.0 \
        && apt clean

# Install GDB - needed for detecting what program created a core file
# & extracting the set of shared libraries.
RUN set -x \
        && apt install -y gdb \
        && apt clean

# Install Lua - Needed for lua-based tests in Couchstore
RUN set -x \
        && apt update \
        && apt install -y lua5.3 lua5.3-dev \
        && apt clean

# Install patch_via_gerrit tool - just use latest
RUN set -x \
        && curl -L https://packages.couchbase.com/patch_via_gerrit/patch_via_gerrit-linux-x86_64 -o /usr/local/bin/patch_via_gerrit \
        && chmod 755 /usr/local/bin/patch_via_gerrit

# Install Ninja for faster builds
RUN set -x \
        && apt update \
        && apt install -y ninja-build \
        && apt clean

# Install chrpath - used to fix libtsan.so's dynamic linker
RUN set -x \
        && apt update \
        && apt install -y chrpath \
        && apt clean

# Install Jython
RUN set -x \
        && curl -sLO https://repo1.maven.org/maven2/org/python/jython-installer/${JYTHON_VERSION}/jython-installer-${JYTHON_VERSION}.jar \
        && mkdir /opt/jython && chown couchbase:couchbase /opt/jython \
        && su couchbase -c "java -jar jython-installer-${JYTHON_VERSION}.jar -s -t minimum -d /opt/jython" \
        && ln -s /opt/jython/bin/jython /usr/local/bin/ \
        && rm -rf /tmp/*

# Install aspell
RUN set -x \
        && apt update \
        && apt install -y aspell \
        && apt clean

# Install patchelf - required to fix rpaths after erlang's Install script
# copies them to a new location
RUN set -x \
        && apt update \
        && apt install -y patchelf \
        && apt clean

# Install xmlsec1 binary - required by python library for testing pySaml2
RUN set -x \
        && apt update \
        && apt install -y xmlsec1 \
        && apt clean

# Add couchbase user to "docker" group on host (999)
# Also include GID 996 for ECS
RUN groupadd -g 999 docker && usermod -a -G docker couchbase
RUN groupadd -g 996 dockerecs && usermod -a -G dockerecs couchbase

# Add startup hook to enable buildx
COPY build/buildx.sh /usr/sbin/couchhook.d/

# Enable additional hook for ccache
COPY cv-hook.sh /usr/sbin/couchhook.d/

# CV stuff (specifically alldependencies.py) still needs python2 :(
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 200

# Enable .gitconfig so repo doesn't get whiny
COPY gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Avoid having to rebuild image chain for simple start script modifications
COPY ./build/couchbuilder_start.sh /usr/sbin/
COPY ./build/healthcheck.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}

RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" >> /home/couchbase/.ssh/environment
