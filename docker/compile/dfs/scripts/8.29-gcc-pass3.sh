#!/bin/bash -ex

# Download all source
dfs-downloader ${GNU_MIRROR}/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz -m ${GCC_CHECKSUM}
tar -xf gcc-${GCC_VERSION}.tar.xz
cd gcc-${GCC_VERSION}
dfs-downloader ${GNU_MIRROR}/gmp/gmp-${GMP_VERSION}.tar.xz -m ${GMP_CHECKSUM}
tar -xf gmp-${GMP_VERSION}.tar.xz
mv gmp-${GMP_VERSION} gmp
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

ln -sv gcc /opt/gcc-${GCC_VERSION}/bin/cc

# Add to ld.so.conf - necessary for built programs to find libstdc++,
# libgomp, etc.
echo "/opt/gcc-${GCC_VERSION}/lib" > /etc/ld.so.conf.d/gcc-${GCC_VERSION}.conf
ldconfig

# Enable link-time optimization
ln -sfv ../../opt/gcc-${GCC_VERSION}/libexec/gcc/$(gcc -dumpmachine)/${GCC_VERSION}/liblto_plugin.so \
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
