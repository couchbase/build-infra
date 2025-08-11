#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/binutils/binutils-${BINUTILS_VERSION}.tar.xz -m ${BINUTILS_CHECKSUM}
tar -xf binutils-${BINUTILS_VERSION}.tar.xz
cd binutils-${BINUTILS_VERSION}

# This patch is needed for ensuring the bintools build doesn't find
# libiberty or zlib from the host. It's quite specific to binutils 2.44
# as it refers to an exact line number; upgrading binutils will require
# tweaking this.
sed '6031s/$add_dir//' -i ltmain.sh

mkdir build
cd build
../configure                   \
    --prefix=/pass2            \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
make -j${PARALLELISM}
make DESTDIR=$LFS install

rm -v $LFS/pass2/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
