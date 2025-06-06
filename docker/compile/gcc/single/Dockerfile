# Docker container just to build GCC, because it's slow.
# Note: A new version of binutils is also bundled

FROM centos:7.9.2009 AS builder
ARG GCC_VER
ARG BINUTILS_VER

# Use vault for package installation - CentOS 7 is now EOL, so the original
# mirrors are no longer available
RUN sed -i -e '/^mirrorlist/d;/^#baseurl=/{s,^#,,;s,/mirror,/vault,;}' /etc/yum.repos.d/CentOS*.repo

# Install the older gcc so we can bootstrap up to the newer, then
# build and install newer.
RUN yum install --setopt=keepcache=0 -y \
        bison \
        bzip2 \
        file \
        gcc \
        gcc-c++ \
        make \
        texinfo \
        wget

ENV PATH=/opt/binutils-${BINUTILS_VER}/bin:$PATH

WORKDIR /tmp
RUN set -x \
      && curl -Lf https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz -o binutils.tar.xz \
      && mkdir binutils && cd binutils \
      && tar xf ../binutils.tar.xz --strip-components=1 \
      && ./configure --prefix=/opt/binutils-${BINUTILS_VER} --enable-gold \
      && make -j$(nproc) \
      && make install \
      && rm -rf /tmp/binutils*

RUN set -x \
      && mkdir /tmp/deploy \
      && cd /tmp/deploy \
      && curl -O https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz \
      && tar xf gcc-${GCC_VER}.tar.xz
RUN cd /tmp/deploy/gcc-${GCC_VER} && ./contrib/download_prerequisites
RUN mkdir /tmp/deploy/objdir
WORKDIR /tmp/deploy/objdir
RUN set -x \
    && sed 's/#define DWARF_VERSION_DEFAULT 5/#define DWARF_VERSION_DEFAULT 4/' /tmp/deploy/gcc-${GCC_VER}/gcc/defaults.h > /tmp/defaults.h.fixed \
    && if cmp -s /tmp/deploy/gcc-${GCC_VER}/gcc/defaults.h /tmp/defaults.h.fixed; then \
      echo "Couldn't set DWARF_VERSION_DEFAULT" && exit 1; \
    else \
      mv /tmp/defaults.h.fixed /tmp/deploy/gcc-${GCC_VER}/gcc/defaults.h; \
    fi
RUN $PWD/../gcc-${GCC_VER}/configure \
      --prefix=/opt/gcc-${GCC_VER} \
      --disable-multilib \
      --enable-languages=c,c++ \
      --enable-debug \
      --disable-strip \
      --with-as=/opt/binutils-${BINUTILS_VER}/bin/as \
      --with-ld=/opt/binutils-${BINUTILS_VER}/bin/ld \
      CFLAGS='-g -O2' \
      LDFLAGS='-Wl,--build-id' \
      LDFLAGS_FOR_TARGET='-Wl,--build-id'
RUN make -j$(nproc)

# We use install-strip for size reasons, but copy non-stripped
# libraries we ship afterward so that we can get debug stack
# traces in production.
RUN make install-strip
RUN set -x \
      && ln -s gcc /opt/gcc-${GCC_VER}/bin/cc \
      && cp -a $(uname -m)-*-linux-gnu/libstdc++-v3/src/.libs/libstdc++.so.6.0.* /opt/gcc-${GCC_VER}/lib64 \
      && cp -a $(uname -m)-*-linux-gnu/libgcc/libgcc_s.so.* /opt/gcc-${GCC_VER}/lib64 \
      && cp -a $(uname -m)-*-linux-gnu/libgomp/.libs/libgomp.so.1.0.* /opt/gcc-${GCC_VER}/lib64

# This will cause g++ to bake "-rpath /opt/gcc-${GCC_VER}/lib64" into all
# binaries it builds, so they'll run correctly on the build systems.
# https://stackoverflow.com/questions/17220872/linking-g-4-8-to-libstdc/17224826#17224826
RUN export PATH=/opt/gcc-${GCC_VER}/bin:${PATH} \
    && g++ -dumpspecs \
         | awk "/^\*link:/ { print; getline; print \"-rpath=/opt/gcc-${GCC_VER}/lib64\", \$0; next } { print }" \
         > $(dirname $(g++ -print-libgcc-file-name))/specs

FROM centos:7.9.2009
ARG GCC_VER
ARG BINUTILS_VER
LABEL maintainer="build-team@couchbase.com"
COPY --from=builder /opt/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
COPY --from=builder /opt/binutils-${BINUTILS_VER} /opt/binutils-${BINUTILS_VER}
