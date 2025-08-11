#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/gettext/gettext-${GETTEXT_VERSION}.tar.xz -m ${GETTEXT_CHECKSUM}
tar -xf gettext-${GETTEXT_VERSION}.tar.xz
cd gettext-${GETTEXT_VERSION}

./configure --disable-shared
make -j${PARALLELISM}
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin
