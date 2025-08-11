#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/coreutils/coreutils-${COREUTILS_VERSION}.tar.xz -m ${COREUTILS_CHECKSUM}
dfs-downloader https://www.linuxfromscratch.org/patches/lfs/12.3/coreutils-9.6-i18n-1.patch -m 6aee45dd3e05b7658971c321d92f44b7
tar -xf coreutils-${COREUTILS_VERSION}.tar.xz

cd coreutils-${COREUTILS_VERSION}

patch -Np1 -i ../coreutils-9.6-i18n-1.patch

autoreconf -fv
automake -af
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime
make -j${PARALLELISM}
make install
mv -v /usr/bin/chroot /usr/sbin
