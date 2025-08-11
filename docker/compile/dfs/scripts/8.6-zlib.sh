#!/bin/bash -ex

dfs-downloader https://zlib.net/zlib-${ZLIB_VERSION}.tar.xz -m ${ZLIB_CHECKSUM}
tar -xf zlib-${ZLIB_VERSION}.tar.xz
cd zlib-${ZLIB_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install

rm -fv /usr/lib/libz.a
