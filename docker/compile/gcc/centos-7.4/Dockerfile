# Docker container just to build GCC, because it's slow.

FROM centos:7.4.1708 as builder

# Install the older gcc so we can bootstrap up to the newer, then
# build and install newer. Note: important to update binutils here,
# as the version in the stock base image has a slightly bogus
# version string that is mis-parsed by the gcc build process.
RUN yum install --setopt=keepcache=0 -y binutils bzip2 gcc gcc-c++ make file wget

ARG GCC_VER=10.2.0

RUN set -x \
      && mkdir /tmp/deploy \
      && cd /tmp/deploy \
      && curl -O https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz \
      && tar xf gcc-${GCC_VER}.tar.xz
RUN cd /tmp/deploy/gcc-${GCC_VER} && ./contrib/download_prerequisites
RUN mkdir /tmp/deploy/objdir
WORKDIR /tmp/deploy/objdir
RUN $PWD/../gcc-${GCC_VER}/configure --prefix=/opt/gcc-${GCC_VER} --disable-multilib --enable-languages=c,c++
RUN make -j8
# We use install-strip for size reasons, but copy the non-stripped
# libstdc++.so.6.0.* afterward (because we ship that file in Server)
# so that we can get debug stack traces in production.
RUN make install-strip
RUN set -x \
      && ln -s gcc /opt/gcc-${GCC_VER}/bin/cc \
      && cp -a x86_64-pc-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.* /opt/gcc-${GCC_VER}/lib64

FROM centos:7.4.1708
LABEL maintainer="build-team@couchbase.com"

ARG GCC_VER=10.2.0

RUN mkdir -p /opt
COPY --from=builder /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
