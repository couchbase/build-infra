#!/bin/bash -ex

dfs-downloader ${GNU_MIRROR}/glibc/glibc-${GLIBC_VERSION}.tar.xz -m ${GLIBC_CHECKSUM}
dfs-downloader https://www.iana.org/time-zones/repository/releases/tzdata${TZDATA_VERSION}.tar.gz -m ${TZDATA_CHECKSUM}

tar -xf glibc-${GLIBC_VERSION}.tar.xz
cd glibc-${GLIBC_VERSION}

# 8.5.1 install glibc

mkdir build
cd build

echo "rootsbindir=/usr/sbin" > configparms

../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=5.4                      \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib

make -j${PARALLELISM}

# Initialize ld.so.conf
mkdir -pv /etc/ld.so.conf.d
echo "include ld.so.conf.d/*.conf" > /etc/ld.so.conf

# We need this for now
echo "/pass2/lib" > /etc/ld.so.conf.d/pass2.conf

sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
make install
sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd

# ...and we need this
ldconfig

# Test case: when building glibc 2.28 with gcc 13.2.0, this fails!
cat > dummy.c << "EOF"
#include <stdio.h>

int main() {
    FILE* file = fopen("testdata.txt", "r");
    unsigned offset;
    long long hash;
    char type[64];

    if (fscanf(file, "%u %llx %26s %*[^\n]\n", &offset, &hash, type) == 3) {
        printf("  offset=%d, hash=%llx, type=%s\n",
               offset, hash, type);
    } else {
        printf("Error: Could not read entry\n");
        return 1;
    }
    fclose(file);
    return 0;
}
EOF
cat > testdata.txt << "EOF"
762 f55225f3e89a6511 RESOLVED_IR _ZN17double_conversion
EOF
gcc -o dummy dummy.c

./dummy

# 8.5.2 configure glibc

# Create locales
mkdir /usr/lib/locale
localedef -i en_US -f UTF-8 en_US.UTF-8

# Create /etc/nsswitch.conf
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

# Add timezone data
cd ${LFS_SRC}
tar -xf tzdata${TZDATA_VERSION}.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO tz

ln -sfv /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
