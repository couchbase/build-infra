#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

dfs-downloader ${GNU_MIRROR}/bash/bash-${BASH_SHELL_VERSION}.tar.gz -m ${BASH_SHELL_CHECKSUM}
tar -xf bash-${BASH_SHELL_VERSION}.tar.gz
cd bash-${BASH_SHELL_VERSION}
./configure --prefix=/pass2                    \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc
make -j${PARALLELISM}
make DESTDIR=$LFS install

# Symlink for sh
ln -sv bash $LFS/bin/sh

# Symlinks for scripts running in pass 3
ln -sfv /pass2/bin/bash $LFS/bin/bash
ln -sfv /pass2/bin/bash $LFS/bin/sh
