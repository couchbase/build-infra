#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/gzip/gzip-${GZIP_VERSION}.tar.xz -m ${GZIP_CHECKSUM}
tar -xf gzip-${GZIP_VERSION}.tar.xz
cd gzip-${GZIP_VERSION}

./configure --prefix=/pass2 --host=$LFS_TGT
make -j${PARALLELISM}
make DESTDIR=$LFS install
