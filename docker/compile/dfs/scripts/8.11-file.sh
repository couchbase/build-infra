#!/bin/bash -ex

dfs-downloader https://astron.com/pub/file/file-${FILE_VERSION}.tar.gz -m ${FILE_CHECKSUM}
tar -xf file-${FILE_VERSION}.tar.gz
cd file-${FILE_VERSION}

# Build and install
./configure --prefix=/usr
make -j${PARALLELISM}
make install
