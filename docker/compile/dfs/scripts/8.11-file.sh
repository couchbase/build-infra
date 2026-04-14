#!/bin/bash -ex

dfs-downloader https://sources.voidlinux.org/file-${FILE_VERSION}/file-${FILE_VERSION}.tar.gz -m ${FILE_CHECKSUM}
tar -xf file-${FILE_VERSION}.tar.gz
cd file-${FILE_VERSION}

# Build and install
./configure --prefix=/usr
make -j${PARALLELISM}
make install
