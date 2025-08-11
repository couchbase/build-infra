#!/bin/bash -ex

dfs-downloader https://www.sudo.ws/dist/sudo-${SUDO_VERSION}.tar.gz -m ${SUDO_CHECKSUM}
tar -xf sudo-${SUDO_VERSION}.tar.gz
cd sudo-${SUDO_VERSION}

./configure --prefix=/usr         \
            --libexecdir=/usr/lib \
            --with-secure-path    \
            --with-env-editor     \
            --docdir=/usr/share/doc/sudo-${SUDO_VERSION} \
            --with-passprompt="[sudo] password for %p: "
make -j${PARALLELISM}
make install
