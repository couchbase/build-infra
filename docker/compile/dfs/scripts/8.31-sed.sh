#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/sed/sed-${SED_VERSION}.tar.gz -m ${SED_CHECKSUM}
tar -xf sed-${SED_VERSION}.tar.gz

cd sed-${SED_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
