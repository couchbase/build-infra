#!/bin/bash -ex

dfs-downloader https://codeberg.org/pere/chrpath/archive/release-${CHRPATH_VERSION}.tar.gz -m ${CHRPATH_CHECKSUM}
tar -xf chrpath-release-${CHRPATH_VERSION}.tar.gz
cd chrpath

./bootstrap
./configure --prefix=/usr
make -j${PARALLELISM}
make docdir=/usr/share/doc/chrpath-${CHRPATH_VERSION} install
