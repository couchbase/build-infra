#!/bin/bash -ex

dfs-downloader https://www.kernel.org/pub/linux/utils/util-linux/v${UTIL_LINUX_VERSION%.*}/util-linux-${UTIL_LINUX_VERSION}.tar.xz -m ${UTIL_LINUX_CHECKSUM}
tar -xf util-linux-${UTIL_LINUX_VERSION}.tar.xz
cd util-linux-${UTIL_LINUX_VERSION}

./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            --without-systemd     \
            --without-systemdsystemunitdir        \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-${UTIL_LINUX_VERSION}
make -j${PARALLELISM}
make install
