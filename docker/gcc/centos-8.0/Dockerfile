# Docker container just to build GCC, because it's slow.

FROM centos:8
MAINTAINER build-team@couchbase.com

ARG GCC_VER=7.3.0

# Install the older gcc so we can bootstrap up to the newer, then
# build and install newer, cleaning up afterwards. This is all
# in one step to minimize the final image size, since we really
# only care about the contents of /usr/local anyway.
# We use install-strip for size reasons, but copy the non-stripped
# libstdc++.so.6.0.24 afterward (because we ship that file in Server)
# so that we can get debug stack traces in production.
COPY ustat.patch /tmp
RUN yum install --setopt=keepcache=0 -y bzip2 diffutils gcc gcc-c++ make file patch xz && \
    yum reinstall -y kernel-headers && \
    rm -rf /usr/local/* && \
    mkdir /tmp/deploy && cd /tmp/deploy && \
    curl -O https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz && \
    tar xf gcc-${GCC_VER}.tar.xz && \
    cd gcc-${GCC_VER} && \
    patch -p1 < /tmp/ustat.patch && \
    ./contrib/download_prerequisites && \
    mkdir /tmp/deploy/objdir && \
    cd /tmp/deploy/objdir && \
    $PWD/../gcc-${GCC_VER}/configure  --prefix=/usr/local --disable-multilib --enable-languages=c,c++ && \
    make -j8 && \
    make install-strip && \
    ln -s gcc /usr/local/bin/cc && \
    cp -a x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.24 /usr/local/lib64 && \
    cd /tmp && rm -rf deploy && \
    yum remove -y bzip2 diffutils gcc gcc-c++ make file patch xz && \
    yum clean all && \
    rm -rf /var/cache/yum
