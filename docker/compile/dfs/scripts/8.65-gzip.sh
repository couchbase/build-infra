#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/gzip/gzip-${GZIP_VERSION}.tar.xz -m ${GZIP_CHECKSUM}
tar -xf gzip-${GZIP_VERSION}.tar.xz
cd gzip-${GZIP_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
