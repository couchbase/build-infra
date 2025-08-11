#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/gawk/gawk-${GAWK_VERSION}.tar.xz -m ${GAWK_CHECKSUM}
tar -xf gawk-${GAWK_VERSION}.tar.xz
cd gawk-${GAWK_VERSION}

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr
make -j${PARALLELISM}
make install
