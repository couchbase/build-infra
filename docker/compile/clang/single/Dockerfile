# Docker container just to build clang, because it's slow.

FROM centos:7.9.2009 as build
COPY --from=couchbasebuild/single-gcc:12.2.0 /opt/gcc-12.2.0 /opt/gcc-12.2.0
ARG CLANG_VER

WORKDIR /tmp

# Clang build needs a newer cmake than is present in distro repos
ARG CMAKE_MAJOR=3
ARG CMAKE_MINOR=25
ARG CMAKE_PATCH=2
RUN set -x \
    && yum install -y gzip tar \
    && curl -o ./cmake.sh https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-$(uname -m).sh \
    && (echo y ; echo n) | sh ./cmake.sh --prefix=/usr/local \
    && rm -rf ./cmake.sh

WORKDIR /tmp
RUN set -x \
    && yum install -y epel-release \
    && yum install -y git glibc-devel ninja-build which \
    && ln -s $(which ninja-build) /usr/local/bin/ninja
RUN set -x \
    && git clone https://github.com/llvm/llvm-project.git
RUN set -x \
    && cd /tmp/llvm-project \
    && git checkout llvmorg-${CLANG_VER}
WORKDIR /tmp/clang-build
RUN set -ex \
    && export PATH=/opt/gcc-12.2.0/bin:$PATH \
    && yum install -y python3 \
    && cd /tmp/llvm-project \
    && cmake ../llvm-project/llvm -G Ninja -Wno-dev \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_C_FLAGS_RELEASE_INIT="$CFLAGS -O2" \
        -DCMAKE_CXX_FLAGS_RELEASE_INIT="$CXXFLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS_RELEASE_INIT="$LDFLAGS -Wl,-z,stack-size=2097152" \
        -DCMAKE_INSTALL_PREFIX=/opt/clang-${CLANG_VER} \
        -DCMAKE_VERBOSE_MAKEFILE=OFF \
        -DCLANG_BUILD_EXAMPLES=OFF \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" \
        -DCLANG_INCLUDE_DOCS=OFF \
        -DLLVM_BUILD_DOCS=OFF \
        -DSPHINX_WARNINGS_AS_ERRORS=OFF \
        -DCLANG_INCLUDE_TESTS=ON \
        -DCLANG_PLUGIN_SUPPORT=ON \
        -DBUILD_SHARED_LIBS=OFF \
    && ninja -j$(nproc) \
    && mkdir /opt/clang-${CLANG_VER} \
    && mv bin include lib libexec share /opt/clang-${CLANG_VER} \
    && rm -rf /tmp/{llvm-project,clang-build}

FROM scratch
ARG CLANG_VER
COPY --from=build /opt/clang-${CLANG_VER} /opt/clang-${CLANG_VER}
