#!/bin/bash -e

LATESTBUILDS=${1-/latestbuilds}

remove_glob() {
  glob=$1
  days=$2
  echo Removing ${glob} older than ${days} days...
  find . -name ${glob} -atime +${days} -exec sh -c 'echo > "{}"; rm "{}"' \;
}

echo @@@@@@@@@
echo Clean up cbdeps builds
echo @@@@@@@@@
cd ${LATESTBUILDS}/cbdeps

remove_glob "*.tgz" 45
remove_glob "*.md5" 45
find . -empty -type d -print -delete

echo @@@@@@@@@
echo Clean up Couchbase Server toy builds
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-server/toybuilds

remove_glob "*.*" 30
find . -empty -type d -print -delete

echo @@@@@@@@@
echo Clean up Couchbase Server
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-server

# All MacOS .orig/-unsigned files from codesigning
remove_glob "*macos*.orig" 2
remove_glob "*macos*-unsigned.zip" 2

# All debug packages older than 60 days
remove_glob "*debug*" 60
remove_glob "*dbg*" 60
remove_glob "*-PDB.zip" 60

# All non-centos7 builds older than 90 days
remove_glob "*amzn2*.rpm" 90
remove_glob "*macos*.zip*" 90
remove_glob "*macos*.dmg*" 90
remove_glob "*linux*.deb*" 90
remove_glob "*linux*.rpm*" 90
remove_glob "*windows*exe*" 90
remove_glob "*windows*msi*" 90
remove_glob "*ubuntu*.deb*" 90
remove_glob "*debian*.deb*" 90
remove_glob "*centos6*.rpm*" 90
remove_glob "*centos8*.rpm*" 90
remove_glob "*suse*.rpm*" 90
remove_glob "*rhel*.rpm*" 90
remove_glob "*oel*.rpm*" 90

echo @@@@@@@@@
echo Clean up couchbase-sync-gateway
echo @@@@@@@@@
cd ${LATESTBUILDS}/sync_gateway

# All tar.gz packages older than 90 days
remove_glob "couchbase-sync-gateway*.tar.gz*" 90

# older than 90 days
remove_glob "*.zip*" 90
remove_glob "*.rpm*" 90
remove_glob "*.msi*" 90
remove_glob "*.deb*" 90

echo @@@@@@@@@
echo Clean up couchbase-lite-core
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-core

# older than 90 days
remove_glob "*.zip" 90
remove_glob "*.tgz" 90
remove_glob "*.tar.gz" 90

echo @@@@@@@@@
echo Clean up couchbase-lite-c
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-c

# older than 90 days
remove_glob "*.zip" 90
remove_glob "*.tgz" 90
remove_glob "*.tar.gz" 90
remove_glob "*.deb" 90


echo @@@@@@@@@
echo Clean up couchbase-lite-android
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-android

# older than 90 days
remove_glob "*.jar*" 90
remove_glob "*.aar*" 90
remove_glob "*.apk*" 90
remove_glob "*.zip*" 90

echo @@@@@@@@@
echo Clean up couchbase-lite-java
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-java
remove_glob "*.jar*" 90
remove_glob "*.war*" 90
remove_glob "*.zip*" 90

echo @@@@@@@@@
echo Clean up couchbase-lite-ios
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-ios

# older than 90 days
remove_glob "*.zip*" 90

echo @@@@@@@@@
echo Clean up couchbase-lite-net
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-net

# older than 90 days
remove_glob "*.nupkg*" 90
remove_glob "*.zip*"   90

echo @@@@@@@@@
echo Clean up couchbase-lite-log
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-log

# older than 90 days
remove_glob "*.zip*" 90
remove_glob "*.rpm*" 90
remove_glob "*.deb*" 90

echo @@@@@@@@@
echo Clean up couchbase-lite-cblite
echo @@@@@@@@@
cd ${LATESTBUILDS}/couchbase-lite-cblite

# older than 90 days
remove_glob "*.zip*" 90

echo @@@@@@@@@
echo Clean up ALL products source tarballs
echo @@@@@@@@@
cd ${LATESTBUILDS}

# All Source tarballs older than 2 days
remove_glob "*source.tar.gz" 2
