#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/mpc/mpc-${MPC_VERSION}.tar.gz -m ${MPC_CHECKSUM}
tar -xf mpc-${MPC_VERSION}.tar.gz
cd mpc-${MPC_VERSION}

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-${MPC_VERSION}

make -j${PARALLELISM}
make install
