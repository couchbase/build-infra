# Docker container just to build GCC, because it's slow.

FROM debian:8.2
MAINTAINER build-team@couchbase.com

ARG GCC_VER=7.2.0

# Install the older gcc so we can bootstrap up to the newer, then
# build and install newer, cleaning up afterwards. This is all
# in one step to minimize the final image size, since we really
# only care about the contents of /usr/local anyway
RUN apt-get update && \
    apt-get install -y file curl build-essential libc6-dev-i386 && \
    rm -rf /usr/local/* && \
    mkdir /tmp/deploy && cd /tmp/deploy && \
    curl -O https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz && \
    tar xf gcc-${GCC_VER}.tar.xz && \
    cd gcc-${GCC_VER} && \
    ./contrib/download_prerequisites && \
    mkdir /tmp/deploy/objdir && \
    cd /tmp/deploy/objdir && \
    $PWD/../gcc-${GCC_VER}/configure  --prefix=/usr/local --disable-multilib --enable-languages=c,c++ && \
    make -j8 && \
    make install-strip && \
    ln -s gcc /usr/local/bin/cc && \
    cd /tmp && rm -rf deploy && \
    apt-get purge -y file curl build-essential libc6-dev-i386 && \
    apt-get --purge autoremove -y && \
    apt-get clean
