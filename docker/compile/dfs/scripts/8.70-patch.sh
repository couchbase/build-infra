#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/patch/patch-${PATCH_VERSION}.tar.gz -m ${PATCH_CHECKSUM}
tar -xf patch-${PATCH_VERSION}.tar.gz
cd patch-${PATCH_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
