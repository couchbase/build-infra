# Docker container just to build GCC, because it's slow.

FROM ubuntu:20.04 AS builder
MAINTAINER build-team@couchbase.com

ARG GCC_VER
ARG PREFIX=/usr/local

COPY build/patches /tmp/patches

# Install the older gcc so we can bootstrap up to the newer, then
# build and install newer, cleaning up afterwards. This is all
# in one step to minimize the final image size, since we really
# only care about the contents of ${PREFIX} anyway.
# We use install-strip for size reasons, but copy the non-stripped
# libstdc++.so.6.0.24 afterward (because we ship that file in Server)
# so that we can get debug stack traces in production.
RUN apt-get update && \
    apt-get install -y file curl build-essential libc6-dev-i386
RUN rm -rf ${PREFIX} && \
    mkdir /tmp/deploy && cd /tmp/deploy && \
    curl -O https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz && \
    tar xf gcc-${GCC_VER}.tar.xz
RUN set -x && \
    cd /tmp/deploy/gcc-${GCC_VER} && \
    for file in /tmp/patches/*.patch; do patch -p0 < ${file}; done && \
    ./contrib/download_prerequisites
RUN mkdir /tmp/deploy/objdir && \
    cd /tmp/deploy/objdir && \
    $PWD/../gcc-${GCC_VER}/configure --prefix=${PREFIX} --disable-multilib --enable-languages=c,c++ && \
    make -j8 && \
    make install-strip && \
    ln -s gcc ${PREFIX}/bin/cc
RUN cd /tmp/deploy/objdir && \
    cp -a x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.24 ${PREFIX}/lib64
