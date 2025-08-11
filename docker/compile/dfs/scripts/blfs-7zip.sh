#!/bin/bash -ex

case $(uname -m) in
    x86_64)
      SEVENZIP_ARCH=x64
      SEVENZIP_CHECKSUM=${SEVENZIP_X86_64_CHECKSUM}
      ;;
    aarch64)
      SEVENZIP_ARCH=arm64
      SEVENZIP_CHECKSUM=${SEVENZIP_AARCH64_CHECKSUM}
      ;;
    *) echo "Unsupported architecture: $(uname -m)" && exit 1 ;;
esac

dfs-downloader https://github.com/ip7z/7zip/releases/download/${SEVENZIP_VERSION}/7z${SEVENZIP_VERSION//./}-linux-${SEVENZIP_ARCH}.tar.xz -m ${SEVENZIP_CHECKSUM}
tar -xf 7z${SEVENZIP_VERSION//./}-linux-${SEVENZIP_ARCH}.tar.xz

# Install it as "7z" since that's what everyone expects
mv 7zz /usr/bin/7z

7z --help
