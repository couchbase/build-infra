#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/make/make-${MAKE_VERSION}.tar.gz -m ${MAKE_CHECKSUM}
tar -xf make-${MAKE_VERSION}.tar.gz
cd make-${MAKE_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
