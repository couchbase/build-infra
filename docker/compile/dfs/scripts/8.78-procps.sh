#!/bin/bash -ex

dfs-downloader https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-${PROCPS_VERSION}.tar.xz -m ${PROCPS_CHECKSUM}
tar -xf procps-ng-${PROCPS_VERSION}.tar.xz
cd procps-ng-${PROCPS_VERSION}

./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.5 \
            --disable-static                        \
            --disable-kill                          \
            --enable-watch8bit
make -j${PARALLELISM}
make install
