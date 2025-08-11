#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/libunistring/libunistring-${LIBUNISTRING_VERSION}.tar.xz -m ${LIBUNISTRING_CHECKSUM}
tar -xf libunistring-${LIBUNISTRING_VERSION}.tar.xz
cd libunistring-${LIBUNISTRING_VERSION}

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/libunistring-${LIBUNISTRING_VERSION}
make -j${PARALLELISM}
make install
