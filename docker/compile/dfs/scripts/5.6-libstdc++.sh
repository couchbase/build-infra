#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/gcc/gcc-${INITIAL_GCC_VERSION}/gcc-${INITIAL_GCC_VERSION}.tar.xz -m ${INITIAL_GCC_CHECKSUM}
tar -xf gcc-${INITIAL_GCC_VERSION}.tar.xz
cd gcc-${INITIAL_GCC_VERSION}

# Set default directory names to 'lib'
case $(uname -m) in
    x86_64)
        sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
        ;;
    aarch64)
        sed -e '/lp64=/s/lib64/lib/' -i.orig gcc/config/aarch64/t-aarch64-linux
        ;;
esac

mkdir build
cd build
../libstdc++-v3/configure         \
  --host=$LFS_TGT                 \
  --build=$(../config.guess)      \
  --prefix=/usr                   \
  --libdir=/usr/lib               \
  --disable-multilib              \
  --disable-nls                   \
  --disable-libstdcxx-pch         \
  --with-gxx-include-dir=/pass1/$LFS_TGT/include/c++/${INITIAL_GCC_VERSION}
make -j${PARALLELISM}
make DESTDIR=$LFS install
rm -v $LFS/usr/lib/lib{stdc++,supc++}*.la
