#!/bin/bash -ex

dfs-downloader https://www.kernel.org/pub/linux/kernel/v${LINUX_VERSION%%.*}.x/linux-${LINUX_VERSION}.tar.xz -m ${LINUX_CHECKSUM}
tar -xf linux-${LINUX_VERSION}.tar.xz
cd linux-${LINUX_VERSION}
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr
