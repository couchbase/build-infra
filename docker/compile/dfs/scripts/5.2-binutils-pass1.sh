#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

ls -lad

dfs-downloader ${GNU_MIRROR}/binutils/binutils-${BINUTILS_VERSION}.tar.xz -m ${BINUTILS_CHECKSUM}
tar -xf binutils-${BINUTILS_VERSION}.tar.xz
cd binutils-${BINUTILS_VERSION}
mkdir build
cd build
../configure --prefix=$LFS/pass1 \
  --with-sysroot=$LFS \
  --target=$LFS_TGT \
  --disable-nls \
  --enable-gprofng=no \
  --disable-werror \
  --enable-new-dtags \
  --enable-default-hash-style=gnu
make -j${PARALLELISM}
make install
