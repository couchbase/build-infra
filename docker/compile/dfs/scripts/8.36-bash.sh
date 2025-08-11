#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/bash/bash-${BASH_SHELL_VERSION}.tar.gz -m ${BASH_SHELL_CHECKSUM}
tar -xf bash-${BASH_SHELL_VERSION}.tar.gz
cd bash-${BASH_SHELL_VERSION}

./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            --docdir=/usr/share/doc/bash-${BASH_SHELL_VERSION}

make -j${PARALLELISM}
make install

ln -svf bash /bin/sh
