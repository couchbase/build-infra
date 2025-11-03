#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/gmp/gmp-${GMP_VERSION}.tar.xz -m ${GMP_CHECKSUM}
tar -xf gmp-${GMP_VERSION}.tar.xz
cd gmp-${GMP_VERSION}

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-${GMP_VERSION}

make -j${PARALLELISM}
make install
