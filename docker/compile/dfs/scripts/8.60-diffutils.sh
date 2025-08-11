#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/diffutils/diffutils-${DIFFUTILS_VERSION}.tar.gz -m ${DIFFUTILS_CHECKSUM}
tar -xf diffutils-${DIFFUTILS_VERSION}.tar.gz
cd diffutils-${DIFFUTILS_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
