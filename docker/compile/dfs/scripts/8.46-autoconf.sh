#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz -m ${AUTOCONF_CHECKSUM}
tar -xf autoconf-${AUTOCONF_VERSION}.tar.gz

cd autoconf-${AUTOCONF_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
