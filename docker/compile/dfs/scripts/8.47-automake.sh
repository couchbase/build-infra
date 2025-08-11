#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/automake/automake-${AUTOMAKE_VERSION}.tar.gz -m ${AUTOMAKE_CHECKSUM}
tar -xf automake-${AUTOMAKE_VERSION}.tar.gz

cd automake-${AUTOMAKE_VERSION}

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.17
make -j${PARALLELISM}
make install
