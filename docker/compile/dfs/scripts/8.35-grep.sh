#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/grep/grep-${GREP_VERSION}.tar.gz -m ${GREP_CHECKSUM}
tar -xf grep-${GREP_VERSION}.tar.gz

cd grep-${GREP_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
