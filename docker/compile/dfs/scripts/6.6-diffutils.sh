#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/diffutils/diffutils-${DIFFUTILS_VERSION}.tar.xz -m ${DIFFUTILS_CHECKSUM}
tar -xf diffutils-${DIFFUTILS_VERSION}.tar.xz
cd diffutils-${DIFFUTILS_VERSION}
./configure --prefix=/pass2 \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install
