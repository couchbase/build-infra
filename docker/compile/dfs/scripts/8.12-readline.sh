#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/readline/readline-${READLINE_VERSION}.tar.gz -m ${READLINE_CHECKSUM}
tar -xf readline-${READLINE_VERSION}.tar.gz
cd readline-${READLINE_VERSION}

# Prevent hard-coding rpath
sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf

# Build and install
./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2.13
make -j${PARALLELISM} SHLIB_LIBS="-lncursesw"
make install
