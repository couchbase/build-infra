#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/libtool/libtool-${LIBTOOL_VERSION}.tar.gz -m ${LIBTOOL_CHECKSUM}
tar -xf libtool-${LIBTOOL_VERSION}.tar.gz

cd libtool-${LIBTOOL_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install

rm -fv /usr/lib/libltdl.a
