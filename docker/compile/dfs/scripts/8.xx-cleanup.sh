#!/bin/bash -ex

# Eliminate the /pass2 tools
rm -rf /pass2 ${LFS_SRC} ${LFS_SCRIPTS}

# Remove /pass2 from ld.so.conf
rm -f /etc/ld.so.conf.d/pass2.conf
ldconfig

# Eliminate unwanted docs and stuff
rm -rf /usr/share/{doc,info,man}

# Remove unwanted localization files
find /usr/share/locale -mindepth 1 -maxdepth 1 -name en\* -prune -o -print | xargs rm -rf
