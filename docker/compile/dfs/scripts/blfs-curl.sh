#!/bin/bash -ex

dfs-downloader https://curl.se/download/curl-${CURL_VERSION}.tar.xz -m ${CURL_CHECKSUM}
tar -xf curl-${CURL_VERSION}.tar.xz
cd curl-${CURL_VERSION}

./configure --prefix=/usr    \
            --disable-static \
            --with-openssl   \
            --with-ca-path=/etc/ssl/certs \
            --disable-docs

make -j${PARALLELISM}

# Install stripped binaries - can't strip them after the fact because
# one file is hard-linked many dozens of times
make install-strip
