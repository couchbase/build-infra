#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/glibc/glibc-${GLIBC_VERSION}.tar.xz -m ${GLIBC_CHECKSUM}
tar -xf glibc-${GLIBC_VERSION}.tar.xz
cd glibc-${GLIBC_VERSION}

# glibc's ld.so will be built as /usr/lib/ld-${GLIBC_VERSION}.so (under
# $LFS), with /usr/lib/ld-linux-x86-64.so.2 as a symlink to it.
# According to LFS, we want these two files in /lib64 to point to that
# file. However, we need to point directly at ld-${GLIBC_VERSION}.so
# rather than indirect through /usr/lib/ld-linux-x86-64.so.2, because
# (much later) uv will use the target of /lib64/ld-linux-x86-64.so.2 to
# introspect the glibc version, and it doesn't follow more than one
# symlink.
case $(uname -m) in
  x86_64)
    ln -sfv ../lib/ld-${GLIBC_VERSION}.so $LFS/lib64/ld-linux-x86-64.so.2
    ln -sfv ../lib/ld-${GLIBC_VERSION}.so $LFS/lib64/ld-lsb-x86-64.so.3
  ;;
esac

mkdir build
cd build
echo "rootsbindir=/usr/sbin" > configparms

../configure                         \
  --disable-werror                   \
  --prefix=/usr                      \
  --host=$LFS_TGT                    \
  --build=$(../scripts/config.guess) \
  --enable-kernel=5.4                \
  --with-headers=$LFS/usr/include    \
  --disable-nscd                     \
  libc_cv_slibdir=/usr/lib

make -j${PARALLELISM}
make DESTDIR=$LFS install
sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

# Basic test
cd /tmp
echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux
rm a.out
