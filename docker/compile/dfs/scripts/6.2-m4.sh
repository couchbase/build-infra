#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/m4/m4-${M4_VERSION}.tar.xz -m ${M4_CHECKSUM}
tar -xf m4-${M4_VERSION}.tar.xz
cd m4-${M4_VERSION}
./configure --prefix=/pass2 \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install