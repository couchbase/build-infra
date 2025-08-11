#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/grep/grep-${GREP_VERSION}.tar.xz -m ${GREP_CHECKSUM}
tar -xf grep-${GREP_VERSION}.tar.xz
cd grep-${GREP_VERSION}

./configure --prefix=/pass2 \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install
