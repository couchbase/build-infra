#!/bin/bash -ex

# Download all source
dfs-downloader ${GNU_MIRROR}/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz -m ${GCC_CHECKSUM}
tar -xf gcc-${GCC_VERSION}.tar.xz
cd gcc-${GCC_VERSION}
dfs-downloader ${GNU_MIRROR}/mpfr/mpfr-${MPFR_VERSION}.tar.xz -m ${MPFR_CHECKSUM}
tar -xf mpfr-${MPFR_VERSION}.tar.xz
mv mpfr-${MPFR_VERSION} mpfr
dfs-downloader ${GNU_MIRROR}/mpc/mpc-${MPC_VERSION}.tar.gz -m ${MPC_CHECKSUM}
tar -xf mpc-${MPC_VERSION}.tar.gz
mv mpc-${MPC_VERSION} mpc

# Set default directory names to 'lib'
case $(uname -m) in
    x86_64)
        sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
        ;;
    aarch64)
        sed -e '/lp64=/s/lib64/lib/' -i.orig gcc/config/aarch64/t-aarch64-linux
        ;;
esac

# Force DWARF version 4 as default
sed 's/#define DWARF_VERSION_DEFAULT 5/#define DWARF_VERSION_DEFAULT 4/' gcc/defaults.h > /tmp/defaults.h.fixed
if cmp -s gcc/defaults.h /tmp/defaults.h.fixed; then
    echo "Couldn't set DWARF_VERSION_DEFAULT" && exit 1
else
    mv /tmp/defaults.h.fixed gcc/defaults.h
fi

mkdir build
cd build
../configure --prefix=/opt/gcc-${GCC_VERSION} \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib

make -j${PARALLELISM}

# Prevent this target from running - it doesn't work for some deeply
# confusing texinfo reason, but we don't want the docs anyway
touch ./gcc/s-tm-texi

make install

# Copy non-stripped libraries we ship so that we can get debug stack
# traces in production. This must happen after make install but before
# the tmpfs is removed
cp -a $(uname -m)-*-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.* /opt/gcc-${GCC_VERSION}/lib
cp -a $(uname -m)-*-linux-gnu/libgcc/libgcc_s.so.* /opt/gcc-${GCC_VERSION}/lib
cp -a $(uname -m)-*-linux-gnu/libgomp/.libs/libgomp.so.1.0.* /opt/gcc-${GCC_VERSION}/lib

ln -sv gcc /opt/gcc-${GCC_VERSION}/bin/cc

# This will cause g++ to bake "-rpath /opt/gcc-${GCC_VERSION}/lib" into all
# binaries it builds, so they'll run correctly on the build systems.
# https://stackoverflow.com/questions/17220872/linking-g-4-8-to-libstdc/17224826#17224826
/opt/gcc-${GCC_VERSION}/bin/g++ -dumpspecs \
    | awk '/^\*link:/ { print; getline; print "-rpath=/opt/gcc-'${GCC_VERSION}'/lib", $0; next } { print }' \
    > $(dirname $(/opt/gcc-${GCC_VERSION}/bin/g++ -print-libgcc-file-name))/specs

# Add to ld.so.conf - necessary for built programs to find libstdc++,
# libgomp, etc.
echo "/opt/gcc-${GCC_VERSION}/lib" > /etc/ld.so.conf.d/gcc-${GCC_VERSION}.conf
ldconfig

# Enable link-time optimization
ln -sfv ../../opt/gcc-${GCC_VERSION}/libexec/gcc/$(/opt/gcc-${GCC_VERSION}/bin/gcc -dumpmachine)/${GCC_VERSION}/liblto_plugin.so \
        /usr/lib/bfd-plugins/

# Basic test
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

success_count=$(grep -E -o 'S?crt[1in].*succeeded' dummy.log|wc -l)
if [ $success_count -ne 3 ]; then
    echo "Expected 3 crt files, found $success_count"
    exit 1
fi
