#!/bin/bash -ex

export LFS_TGT=$(uname -m)-lfs-linux-gnu

# Download all source
dfs-downloader ${GNU_MIRROR}/gcc/gcc-${INITIAL_GCC_VERSION}/gcc-${INITIAL_GCC_VERSION}.tar.xz -m ${INITIAL_GCC_CHECKSUM}
tar -xf gcc-${INITIAL_GCC_VERSION}.tar.xz
cd gcc-${INITIAL_GCC_VERSION}
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
../configure                \
  --target=$LFS_TGT         \
  --prefix=$LFS/pass1       \
  --with-glibc-version=${GLIBC_VERSION} \
  --with-sysroot=$LFS       \
  --with-newlib             \
  --without-headers         \
  --enable-default-pie      \
  --enable-default-ssp      \
  --disable-nls             \
  --disable-shared          \
  --disable-multilib        \
  --disable-threads         \
  --disable-libatomic       \
  --disable-libgomp         \
  --disable-libquadmath     \
  --disable-libssp          \
  --disable-libvtv          \
  --disable-libstdcxx       \
  --enable-languages=c,c++
make -j${PARALLELISM}
make install

# Fix limits.h
cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > $(dirname $($LFS_TGT-gcc -print-libgcc-file-name))/include/limits.h
