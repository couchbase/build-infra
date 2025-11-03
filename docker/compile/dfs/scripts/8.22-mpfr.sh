#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/mpfr/mpfr-${MPFR_VERSION}.tar.xz -m ${MPFR_CHECKSUM}
tar -xf mpfr-${MPFR_VERSION}.tar.xz
cd mpfr-${MPFR_VERSION}

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-${MPFR_VERSION}

make -j${PARALLELISM}
make install
