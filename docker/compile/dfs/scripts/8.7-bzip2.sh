#!/bin/bash -ex

dfs-downloader https://www.sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz -m ${BZIP2_CHECKSUM}
tar -xf bzip2-${BZIP2_VERSION}.tar.gz
cd bzip2-${BZIP2_VERSION}

sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
make -f Makefile-libbz2_so
make clean

make -j${PARALLELISM}
make PREFIX=/usr install

cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so

cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done
rm -fv /usr/lib/libbz2.a
