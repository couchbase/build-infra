#!/bin/bash -ex

dfs-downloader https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz -m ${FLEX_CHECKSUM}
tar -xf flex-${FLEX_VERSION}.tar.gz
cd flex-${FLEX_VERSION}

# The `-D_GNU_SOURCE` option is needed with glibc > 2.26, apparently.
# https://github.com/westes/flex/issues/442#issuecomment-604773156
./configure CFLAGS='-g -O2 -D_GNU_SOURCE' \
            --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
make -j${PARALLELISM}
make install

ln -sv flex   /usr/bin/lex
