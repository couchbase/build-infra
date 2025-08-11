#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/make/make-${PASS2_MAKE_VERSION}.tar.gz -m ${PASS2_MAKE_CHECKSUM}
tar -xf make-${PASS2_MAKE_VERSION}.tar.gz
cd make-${PASS2_MAKE_VERSION}

./configure --prefix=/pass2 \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
make -j${PARALLELISM}
make DESTDIR=$LFS install
