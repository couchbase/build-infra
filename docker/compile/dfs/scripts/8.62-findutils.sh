#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/findutils/findutils-${FINDUTILS_VERSION}.tar.xz -m ${FINDUTILS_CHECKSUM}
tar -xf findutils-${FINDUTILS_VERSION}.tar.xz
cd findutils-${FINDUTILS_VERSION}

./configure --prefix=/usr --localstatedir=/var/lib/locate
make -j${PARALLELISM}
make install
