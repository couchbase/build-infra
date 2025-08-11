#!/bin/bash -ex

dfs-downloader https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz -m ${GIT_CHECKSUM}
tar -xf git-${GIT_VERSION}.tar.xz
cd git-${GIT_VERSION}

./configure --prefix=/usr \
            --with-gitconfig=/etc/gitconfig
make -j${PARALLELISM}
make INSTALL_STRIP=-s install
