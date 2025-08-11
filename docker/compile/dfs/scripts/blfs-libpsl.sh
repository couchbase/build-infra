#!/bin/bash -ex

dfs-downloader https://github.com/rockdaboot/libpsl/releases/download/${LIBPSL_VERSION}/libpsl-${LIBPSL_VERSION}.tar.gz -m ${LIBPSL_CHECKSUM}
tar -xf libpsl-${LIBPSL_VERSION}.tar.gz
cd libpsl-${LIBPSL_VERSION}

mkdir build
cd build

uv tool run meson setup --prefix=/usr --buildtype=release
ninja
ninja install
