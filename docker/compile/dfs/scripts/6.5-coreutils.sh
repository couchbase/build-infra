#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/coreutils/coreutils-${COREUTILS_VERSION}.tar.xz -m ${COREUTILS_CHECKSUM}
tar -xf coreutils-${COREUTILS_VERSION}.tar.xz
cd coreutils-${COREUTILS_VERSION}
./configure --prefix=/pass2                   \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
make -j${PARALLELISM}
make DESTDIR=$LFS install
