#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/tar/tar-${TAR_VERSION}.tar.xz -m ${TAR_CHECKSUM}
tar -xf tar-${TAR_VERSION}.tar.xz
cd tar-${TAR_VERSION}

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr
make -j${PARALLELISM}
make install
