#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/libidn/libidn2-${LIBIDN2_VERSION}.tar.gz -m ${LIBIDN2_CHECKSUM}
tar -xf libidn2-${LIBIDN2_VERSION}.tar.gz
cd libidn2-${LIBIDN2_VERSION}

./configure --prefix=/usr --disable-static
make -j${PARALLELISM}
make install
