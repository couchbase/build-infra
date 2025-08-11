#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/tar/tar-${TAR_VERSION}.tar.xz -m ${TAR_CHECKSUM}
tar -xf tar-${TAR_VERSION}.tar.xz
cd tar-${TAR_VERSION}
./configure --prefix=/pass2                   \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install
