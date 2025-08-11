#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/libtasn1/libtasn1-${LIBTASN1_VERSION}.tar.gz -m ${LIBTASN1_CHECKSUM}
tar -xf libtasn1-${LIBTASN1_VERSION}.tar.gz
cd libtasn1-${LIBTASN1_VERSION}

./configure --prefix=/usr --disable-static
make -j${PARALLELISM}
make install
