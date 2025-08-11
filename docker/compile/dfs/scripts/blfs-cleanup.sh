#!/bin/bash -ex

# Get rid of UV and the download script; everything uv installed; all
# the build scripts; and anything in /tmp.
rm -rf \
    /usr/bin/dfs-downloader /usr/bin/uv \
    /root/.local /root/.cache \
    ${LFS_SCRIPTS} ${LFS_SRC} \
    /tmp/*

# Eliminate unwanted docs and stuff
rm -rf \
    /usr/share/{doc,info,man} \
    /usr/man \
    /opt/gcc-*/share/{info,locale,man}

# Remove unwanted localization files
find /usr/share/locale -mindepth 1 -maxdepth 1 -name en\* -prune -o -print | xargs rm -rf
