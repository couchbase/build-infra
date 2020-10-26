# Docker container for Ubuntu 18.04

FROM couchbasebuild/server-ubuntu18-clang9-build:20201026
LABEL maintainer="build-team@couchbase.com"

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

# Valgrind needed for leak checking as part of unit tests. Note: It requires
# libc debug symbols (libc6-dbg) to ensure it can locate the address of strlen().
RUN set -x \
        && wget -qO- ftp://sourceware.org/pub/valgrind/valgrind-3.13.0.tar.bz2 | tar -xjf - --strip-components=1 \
        && ./configure --prefix=/usr/local && make -j8 && make install \
        && apt update && apt install -y libc6-dbg \
        && rm -rf /tmp/* && ccache --clear && apt clean

# Code coverage requires gcovr to convert from gcov to XML files consumable by Jenkins.
# Also, if we eventually remove paramiko from the main buildslave image, we could add
# it back here for CV.
RUN pip install gcovr

# Install clang-tools for scan-build for older branches
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/bionic/ llvm-toolchain-bionic-6.0 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-tools-6.0 \
        && apt clean

# Install clang-format from Clang 6.0 - needed for checking if formatting of patch is correct for older branches
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/bionic/ llvm-toolchain-bionic-6.0 main" > /etc/apt/sources.list.d/llvm.list \
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

# Install patch_via_gerrit tool
RUN set -x \
        && curl -L https://packages.couchbase.com/patch_via_gerrit/1.0.0/patch_via_gerrit-1.0.0-linux -o /usr/local/bin/patch_via_gerrit \
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
ENV JYTHON_VERSION=2.7.2
RUN set -x \
        && curl -sLO https://repo1.maven.org/maven2/org/python/jython-installer/${JYTHON_VERSION}/jython-installer-${JYTHON_VERSION}.jar \
        && mkdir /opt/jython && chown couchbase:couchbase /opt/jython \
        && su couchbase -c "java -jar jython-installer-${JYTHON_VERSION}.jar -s -t minimum -d /opt/jython" \
        && ln -s /opt/jython/bin/jython /usr/local/bin/ \
        && rm -rf /tmp/*

# Enable .gitconfig so repo doesn't get whiny
COPY gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}

RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" >> /home/couchbase/.ssh/environment
