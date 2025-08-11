#!/bin/bash -ex

dfs-downloader https://github.com/besser82/libxcrypt/releases/download/v${LIBXCRYPT_VERSION}/libxcrypt-${LIBXCRYPT_VERSION}.tar.xz -m ${LIBXCRYPT_CHECKSUM}
tar -xf libxcrypt-${LIBXCRYPT_VERSION}.tar.xz
cd libxcrypt-${LIBXCRYPT_VERSION}

./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens
make -j${PARALLELISM}
make install
