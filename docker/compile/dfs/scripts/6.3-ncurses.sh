#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/ncurses/ncurses-${NCURSES_VERSION}.tar.gz -m ${NCURSES_CHECKSUM}
tar -xf ncurses-${NCURSES_VERSION}.tar.gz
cd ncurses-${NCURSES_VERSION}

# Create 'tic'
mkdir build
pushd build
../configure AWK=gawk
make -C include -j${PARALLELISM}
make -C progs -j${PARALLELISM} tic
popd

# Main ncurses build
./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping          \
            AWK=gawk
make -j${PARALLELISM}

# Install
make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h
