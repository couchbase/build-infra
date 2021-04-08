# Docker container just to build GCC, because it's slow.

FROM suse/sles12sp2:latest
MAINTAINER build-team@couchbase.com

USER root
ARG REGCODE
ARG GCC_VER=10.2.0

# Install the older gcc so we can bootstrap up to the newer, then
# build and install newer, cleaning up afterwards. This is all
# in one step to minimize the final image size, since we really
# only care about the contents of /opt/gcc-* anyway.
# We use install-strip for size reasons, but copy the non-stripped
# libstdc++.so.6.0.24 afterward (because we ship that file in Server)
# so that we can get debug stack traces in production.
RUN zypper ref -s && \
    zypper install -y SUSEConnect && \
    SUSEConnect -r ${REGCODE} -e kenneth.lareau@couchbase.com && \
    SUSEConnect -p sle-sdk/12.2/x86_64 && \
    zypper ref -s && \
    zypper -n install curl gcc gcc-c++ make tar && \
    zypper -n install -t pattern Basis-Devel && \
    rm -rf /opt/gcc-*/* && \
    mkdir /tmp/deploy && cd /tmp/deploy && \
    curl -O https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz && \
    tar xf gcc-${GCC_VER}.tar.xz && \
    cd gcc-${GCC_VER} && \
    ./contrib/download_prerequisites && \
    mkdir /tmp/deploy/objdir && \
    cd /tmp/deploy/objdir && \
    $PWD/../gcc-${GCC_VER}/configure  --prefix=/opt/gcc-${GCC_VER} --disable-multilib --enable-languages=c,c++ && \
    make -j8 && \
    make install-strip && \
    ln -s gcc /opt/gcc-${GCC_VER}/bin/cc && \
    cp -a x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.* /opt/gcc-${GCC_VER}/lib64 && \
    cd /tmp && rm -rf deploy && \
    zypper -n rm curl gcc gcc-c++ make tar && \
    zypper -n rm -t pattern Basis-Devel && \
    zypper clean

# This will cause g++ to bake "-rpath /opt/gcc-10.2.0/lib64" into all
# binaries it builds, so they'll run correctly on the build systems.
# https://stackoverflow.com/questions/17220872/linking-g-4-8-to-libstdc/17224826#17224826
RUN export PATH=/opt/gcc-${GCC_VER}/bin:${PATH} \
    && g++ -dumpspecs \
         | awk "/^\*link:/ { print; getline; print \"-rpath=/opt/gcc-${GCC_VER}/lib64\", \$0; next } { print }" \
         > $(dirname $(g++ -print-libgcc-file-name))/specs
