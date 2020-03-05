# Docker container for Ubuntu 16.04

FROM couchbasebuild/server-ubuntu16-build:20200211
MAINTAINER build-team@couchbase.com

USER root

# Valgrind needed for leak checking as part of unit tests. Note: It requires
# libc debug symbols (libc6-dbg) to ensure it can locate the address of strlen().
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && curl -L -O ftp://sourceware.org/pub/valgrind/valgrind-3.13.0.tar.bz2 && \
    tar -xjf valgrind-3.13.0.tar.bz2 && cd valgrind-3.13.0 && \
    ./configure --prefix=/usr/local && make -j8 && make install && \
    cd /tmp && rm -fr /tmp/deploy && \
    ccache --clear && \
    apt-get update &&  apt-get install -y libc6-dbg && \
    rm -f /var/cache/apt/archives/*.deb

# Code coverage requires gcovr to convert from gcov to XML files consumable by Jenkins.
# Also, if we eventually remove paramiko from the main buildslave image, we could add
# it back here for CV.
RUN pip install gcovr

# Install Clang 6.0 - needed for building with ThreadSanitizer for older branches.
# (Note: This doesn't change the default compiler; users must explicitly
# select clang-6.0 / clang++-6.0).
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-6.0 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install --assume-yes clang-6.0 && \
    rm -fr /var/cache/apt/archives/*.deb

# Install clang-tools for scan-build for older branches
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-6.0 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install --assume-yes clang-tools-6.0 && \
    rm -fr /var/cache/apt/archives/*.deb

# Install clang-format from Clang 6.0 - needed for checking if formatting of patch is correct for older branches
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-6.0 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install --assume-yes --force-yes clang-format-6.0 && \
    rm -fr /var/cache/apt/archives/*.deb

# Install Clang 9 (current stable) - needed for building with ThreadSanitizer.
# (Note: This doesn't change the default compiler; users must explicitly
# select clang-9 / clang++-9).
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install --assume-yes clang-9 && \
    rm -fr /var/cache/apt/archives/*.deb

# Install clang-tools for scan-build
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install --assume-yes clang-tools-9 && \
    rm -fr /var/cache/apt/archives/*.deb

# Install clang-format from Clang 9 - needed for checking if formatting of patch is correct
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install --assume-yes --force-yes clang-format-9 && \
    rm -fr /var/cache/apt/archives/*.deb

# Install clang-tidy from Clang 9 - needed to check and fix basic coding errors
RUN wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - && \
    echo "deb http://llvm.org/apt/xenial/ llvm-toolchain-xenial-9 main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get install --assume-yes --force-yes clang-tidy-9 && \
    rm -fr /var/cache/apt/archives/*.deb

# Create symlinks so clang picks up gcc 7.3.0 and associated libraries
RUN cd /usr/lib/gcc/x86_64-linux-gnu && \
    ln -s /usr/local/lib/gcc/x86_64-pc-linux-gnu/7.3.0 . && \
    mkdir -p /usr/local/include/x86_64-linux-gnu/c++ && \
    cd /usr/local/include/x86_64-linux-gnu/c++ && \
    ln -s ../../c++/7.3.0/x86_64-pc-linux-gnu 7.3.0

# Install GDB - needed for detecting what program created a core file
# & extracting the set of shared libraries.
RUN apt-get install -y gdb && \
    rm -f /var/cache/apt/archives/*.deb

# Install Lua - Needed for lua-based tests in Couchstore
RUN apt-get update && \
    apt-get install -y lua5.3 lua5.3-dev && \
    rm -fr /var/cache/apt/archives/*.deb

# Install patch_via_gerrit tool
RUN curl -L https://packages.couchbase.com/patch_via_gerrit/1.0.0/patch_via_gerrit-1.0.0-linux -o /usr/local/bin/patch_via_gerrit && \
    chmod 755 /usr/local/bin/patch_via_gerrit

# Install Ninja for faster builds
RUN apt-get update && \
    apt-get install -y ninja-build && \
    rm -fr /var/cache/apt/archives/*.deb

# Enable .gitconfig so repo doesn't get whiny
COPY gitconfig /home/couchbase/.gitconfig
RUN chown couchbase:couchbase /home/couchbase/.gitconfig

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
RUN echo "CONTAINER_TAG=${CONTAINER_TAG}" >> /home/couchbase/.ssh/environment

