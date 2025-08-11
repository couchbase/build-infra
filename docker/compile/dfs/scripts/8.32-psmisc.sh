#!/bin/bash -ex

dfs-downloader https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-${PSMISC_VERSION}.tar.xz -m ${PSMISC_CHECKSUM}
tar -xf psmisc-${PSMISC_VERSION}.tar.xz

cd psmisc-${PSMISC_VERSION}

./configure --prefix=/usr
make -j${PARALLELISM}
make install
