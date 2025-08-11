#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader https://astron.com/pub/file/file-${FILE_VERSION}.tar.gz -m ${FILE_CHECKSUM}
tar -xf file-${FILE_VERSION}.tar.gz
cd file-${FILE_VERSION}

# Make a local copy of the "file" command
mkdir build
pushd build
../configure --disable-bzlib      \
             --disable-libseccomp \
             --disable-xzlib      \
             --disable-zlib
make -j${PARALLELISM}
popd

# Build and install the real package
./configure --prefix=/pass2 --host=$LFS_TGT --build=$(./config.guess)
make -j${PARALLELISM} FILE_COMPILE=$(pwd)/build/src/file
make DESTDIR=$LFS install

# Clean an unwanted file
rm -v $LFS/pass2/lib/libmagic.la
