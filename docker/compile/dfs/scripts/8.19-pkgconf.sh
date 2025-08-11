#!/bin/bash -ex

dfs-downloader https://distfiles.ariadne.space/pkgconf/pkgconf-${PKGCONF_VERSION}.tar.xz -m ${PKGCONF_CHECKSUM}
tar -xf pkgconf-${PKGCONF_VERSION}.tar.xz
cd pkgconf-${PKGCONF_VERSION}

./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.3.0
make -j${PARALLELISM}
make install

ln -sv pkgconf   /usr/bin/pkg-config
