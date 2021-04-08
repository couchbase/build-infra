# Docker container just to build GCC, because it's slow.

FROM amazonlinux:2 as builder
LABEL maintainer="build-team@couchbase.com"

ARG GCC_VER=10.2.0

RUN yum install --setopt=keepcache=0 -y bzip2 gcc gcc-c++ make file gzip tar xz
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

# This will cause g++ to bake "-rpath /opt/gcc-10.2.0/lib64" into all
# binaries it builds, so they'll run correctly on the build systems.
# https://stackoverflow.com/questions/17220872/linking-g-4-8-to-libstdc/17224826#17224826
RUN export PATH=/opt/gcc-${GCC_VER}/bin:${PATH} \
    && g++ -dumpspecs \
         | awk "/^\*link:/ { print; getline; print \"-rpath=/opt/gcc-${GCC_VER}/lib64\", \$0; next } { print }" \
         > $(dirname $(g++ -print-libgcc-file-name))/specs

FROM amazonlinux:2
LABEL maintainer="build-team@couchbase.com"

ARG GCC_VER=10.2.0

RUN mkdir -p /opt
COPY --from=builder /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
