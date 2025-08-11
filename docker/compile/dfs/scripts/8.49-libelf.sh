#!/bin/bash -ex

dfs-downloader https://sourceware.org/ftp/elfutils/${LIBELF_VERSION}/elfutils-${LIBELF_VERSION}.tar.bz2 -m ${LIBELF_CHECKSUM}
tar -xf elfutils-${LIBELF_VERSION}.tar.bz2
cd elfutils-${LIBELF_VERSION}

./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy

make -j${PARALLELISM}
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a
