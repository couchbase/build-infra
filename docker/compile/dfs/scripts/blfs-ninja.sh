#!/bin/bash -ex

case $(uname -m) in
    x86_64)
      NINJA_PKG=ninja-linux.zip
      NINJA_CHECKSUM=${NINJA_X86_64_CHECKSUM}
      ;;
    aarch64)
      NINJA_PKG=ninja-linux-aarch64.zip
      NINJA_CHECKSUM=${NINJA_AARCH64_CHECKSUM}
      ;;
    *) echo "Unsupported architecture: $(uname -m)" && exit 1 ;;
esac

dfs-downloader https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/${NINJA_PKG} -m ${NINJA_CHECKSUM}
7z x ${NINJA_PKG}
mv ninja /usr/bin/

ninja --version
