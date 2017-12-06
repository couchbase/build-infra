# Docker container just to build GCC, because it's slow.

FROM suse/sles12sp2:latest
MAINTAINER build-team@couchbase.com

USER root
ARG REGCODE
ARG GCC_VER=7.2.0

# Install the older gcc so we can bootstrap up to the newer, then
# build and install newer, cleaning up afterwards. This is all
# in one step to minimize the final image size, since we really
# only care about the contents of /usr/local anyway
RUN zypper ref -s && \
    zypper install -y SUSEConnect && \
    SUSEConnect -r ${REGCODE} -e kenneth.lareau@couchbase.com && \
    SUSEConnect -p sle-sdk/12.2/x86_64 && \
    zypper ref -s && \
    zypper -n install curl gcc gcc-c++ make tar && \
    zypper -n install -t pattern Basis-Devel && \
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
    zypper -n rm curl gcc gcc-c++ make tar && \
    zypper -n rm -t pattern Basis-Devel && \
    zypper clean
