#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/m4/m4-${M4_VERSION}.tar.xz -m ${M4_CHECKSUM}
tar -xf m4-${M4_VERSION}.tar.xz
cd m4-${M4_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
