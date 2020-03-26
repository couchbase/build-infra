# Docker container for Ubuntu 16.04

FROM couchbasebuild/server-ubuntu16-build:20200211
LABEL maintainer="build-team@couchbase.com"

USER root

WORKDIR /tmp

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

# apt-transport-https is required to install clang
RUN set -x \
        && apt update \
        && apt install apt-transport-https \
        && apt clean

# Install Clang 6.0 - needed for building with ThreadSanitizer for older branches.
# (Note: This doesn't change the default compiler; users must explicitly
# select clang-6.0 / clang++-6.0).
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-6.0 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-6.0 \
        && apt clean

# Install clang-tools for scan-build for older branches
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-6.0 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-tools-6.0 \
        && apt clean

# Install clang-format from Clang 6.0 - needed for checking if formatting of patch is correct for older branches
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-6.0 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-format-6.0 \
        && apt clean

# Install Clang 9 (current stable) - needed for building with ThreadSanitizer.
# (Note: This doesn't change the default compiler; users must explicitly
# select clang-9 / clang++-9).
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-9 \
        && apt clean

# Install clang-tools for scan-build
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-tools-9 \
        && apt clean

# Install clang-format from Clang 9 - needed for checking if formatting of patch is correct
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-format-9 \
        && apt clean

# Install clang-tidy from Clang 9 - needed to check and fix basic coding errors
RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y clang-tidy-9 \
        && apt clean

# Create symlinks so clang picks up gcc 7.3.0 and associated libraries
RUN set -x \
        && mkdir -p /usr/local/include/x86_64-linux-gnu/c++ \
        && ln -s /usr/local/lib/gcc/x86_64-pc-linux-gnu/7.3.0 /usr/lib/gcc/x86_64-linux-gnu \
        && ln -s /usr/local/include/c++/7.3.0/x86_64-pc-linux-gnu /usr/local/include/x86_64-linux-gnu/c++/7.3.0

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

# Install Jython
ENV JYTHON_VERSION=2.7.2
RUN set -x \
        && curl -sLO https://repo1.maven.org/maven2/org/python/jython-installer/${JYTHON_VERSION}/jython-installer-${JYTHON_VERSION}.jar \
        && java -jar jython-installer-${JYTHON_VERSION}.jar -s -t minimum -d /opt/jython \
        && ln -s /opt/jython/bin/jython /usr/local/bin/ \
        && rm -rf /tmp/*

# Enable .gitconfig so repo doesn't get whiny
COPY gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" >> /home/couchbase/.ssh/environment
