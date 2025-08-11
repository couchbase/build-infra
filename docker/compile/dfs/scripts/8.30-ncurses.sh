#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/ncurses/ncurses-${NCURSES_VERSION}.tar.gz -m ${NCURSES_CHECKSUM}
tar -xf ncurses-${NCURSES_VERSION}.tar.gz
cd ncurses-${NCURSES_VERSION}

# Main ncurses build
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
make -j${PARALLELISM}

# Install in such a way that the current shell process won't crash
make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /

# Trick older applications that expect the non-wide character versions
# of the libraries
for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done

ln -sfv libncursesw.so /usr/lib/libcurses.so
