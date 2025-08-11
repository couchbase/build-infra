#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/findutils/findutils-${FINDUTILS_VERSION}.tar.xz -m ${FINDUTILS_CHECKSUM}
tar -xf findutils-${FINDUTILS_VERSION}.tar.xz
cd findutils-${FINDUTILS_VERSION}
./configure --prefix=/pass2                 \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install
