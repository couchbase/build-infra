# Docker container just to build clang, because it's slow.
ARG GCC_CONTAINER
FROM ${GCC_CONTAINER} as gcc

FROM centos:7.9.2009 as build
ARG GCC_VER
COPY --from=gcc /opt /opt
ARG CLANG_VER

WORKDIR /tmp

# Clang build needs a newer cmake than is present in distro repos
ARG CMAKE_MAJOR=3
ARG CMAKE_MINOR=25
ARG CMAKE_PATCH=2
RUN set -x \
    && yum install -y --setopt=skip_missing_names_on_install=False gzip tar \
    && curl -o ./cmake.sh https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-$(uname -m).sh \
    && (echo y ; echo n) | sh ./cmake.sh --prefix=/usr/local \
    && rm -rf ./cmake.sh

WORKDIR /tmp
RUN set -x \
    && yum install -y epel-release \
    && yum install -y --setopt=skip_missing_names_on_install=False git glibc-devel ninja-build python3 which \
    && ln -s $(which ninja-build) /usr/local/bin/ninja
RUN set -x \
    && git clone https://github.com/llvm/llvm-project.git
RUN set -x \
    && cd /tmp/llvm-project \
    && git checkout llvmorg-${CLANG_VER}

ENV PATH=/opt/gcc-${GCC_VER}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WORKDIR /tmp/llvm-project

# Some missing includes in 9
RUN if [ "$(echo ${CLANG_VER} | cut -d. -f1)" = "9" ]; then \
        sed -i'' '/#include <array>/a #include <string>\n#include <cstdint>' llvm/include/llvm/Demangle/MicrosoftDemangleNodes.h; \
        sed -i'' '/#include <vector>/a #include <limits>' llvm/utils/benchmark/src/benchmark_register.h; \
    fi

RUN cmake ../llvm-project/llvm -G Ninja -Wno-dev \
        -DBUILD_SHARED_LIBS="ON" \
        -DCLANG_BUILD_EXAMPLES="OFF" \
        -DCLANG_INCLUDE_DOCS="OFF" \
        -DCLANG_INCLUDE_TESTS="OFF" \
        -DCLANG_PLUGIN_SUPPORT="ON" \
        -DCMAKE_BUILD_TYPE="MinSizeRel" \
        -DCMAKE_C_FLAGS_RELEASE_INIT="$CFLAGS -O2" \
        -DCMAKE_CXX_FLAGS_RELEASE_INIT="$CXXFLAGS" \
        -DCMAKE_EXE_LINKER_FLAGS_RELEASE_INIT="$LDFLAGS -Wl,-z,stack-size=2097152" \
        -DCMAKE_INSTALL_PREFIX="/opt/clang-${CLANG_VER}" \
        -DCMAKE_VERBOSE_MAKEFILE="OFF" \
        -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR="ON" \
        -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;lld" \
        -DLLVM_BUILD_DOCS="OFF"
RUN ninja -j4
RUN mkdir /opt/clang-${CLANG_VER} \
    && mv bin include lib libexec share /opt/clang-${CLANG_VER} \
    && ln -s /opt/clang-${CLANG_VER}/bin/clang++ /opt/clang-${CLANG_VER}/bin/clang++-$(echo $CLANG_VER | cut -d. -f1)\
    && rm -rf /tmp/{llvm-project,clang-build}

FROM scratch
ARG CLANG_VER
COPY --from=build /opt/clang-${CLANG_VER} /opt/clang-${CLANG_VER}
