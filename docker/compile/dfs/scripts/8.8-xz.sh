#!/bin/bash -ex

dfs-downloader https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.xz -m ${XZ_CHECKSUM}
tar -xf xz-${XZ_VERSION}.tar.xz
cd xz-${XZ_VERSION}

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.6.4
make -j${PARALLELISM}
make install
