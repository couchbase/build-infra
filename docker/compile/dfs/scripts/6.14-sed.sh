#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/sed/sed-${SED_VERSION}.tar.xz -m ${SED_CHECKSUM}
tar -xf sed-${SED_VERSION}.tar.xz
cd sed-${SED_VERSION}
./configure --prefix=/pass2   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install
