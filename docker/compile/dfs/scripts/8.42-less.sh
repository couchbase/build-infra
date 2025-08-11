#!/bin/bash -ex

dfs-downloader https://www.greenwoodsoftware.com/less/less-${LESS_VERSION}.tar.gz -m ${LESS_CHECKSUM}
tar -xf less-${LESS_VERSION}.tar.gz
cd less-${LESS_VERSION}
./configure --prefix=/usr --sysconfdir=/etc
make -j${PARALLELISM}
make install
