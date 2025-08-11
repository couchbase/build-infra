#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/patch/patch-${PATCH_VERSION}.tar.gz -m ${PATCH_CHECKSUM}
tar -xf patch-${PATCH_VERSION}.tar.gz
cd patch-${PATCH_VERSION}

./configure --prefix=/pass2 \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install
