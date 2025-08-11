#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/bison/bison-${BISON_VERSION}.tar.xz -m ${BISON_CHECKSUM}
tar -xf bison-${BISON_VERSION}.tar.xz
cd bison-${BISON_VERSION}

./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2
make -j${PARALLELISM}
make install
