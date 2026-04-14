# Docker container just to build one Clang version for DFS, because it's slow.

FROM couchbasebuild/server-builder:20260408 AS base
LABEL maintainer="build-team@couchbase.com"

USER root

ARG CLANG_VERSION
ARG GCC_VERSION
ARG tmpsrc=/tmp/deploy
ARG PARALLELISM=8
WORKDIR ${tmpsrc}

FROM base AS clang_build
ARG CLANG_VERSION
ARG GCC_VERSION

COPY <<'EOF' /tmp/build-clang.sh
#!/bin/bash -ex
VERSION=$1
GCC_VERSION=$2
GCC_DIR="gcc-${GCC_VERSION}"
curl -L https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${VERSION}.tar.gz | tar -xzf - --strip-components=1
cmake -S llvm -B build -G Ninja \
    -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/opt/clang-${VERSION} \
    -DLLVM_PARALLEL_LINK_JOBS=3 \
    -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON \
    -DLLVM_INCLUDE_TESTS=Off \
    -DCLANG_INCLUDE_TESTS=Off \
    -DLLVM_INCLUDE_EXAMPLES=Off \
    -DCLANG_BUILD_EXAMPLES=Off \
    -DCLANG_INCLUDE_DOCS=Off \
    -DLLVM_BUILD_DOCS=Off
cmake --build build -j${PARALLELISM}
cmake --install build
rm -rf ${tmpsrc}/*
ln -s /opt/clang-${VERSION}/bin/clang++ /opt/clang-${VERSION}/bin/clang++-$(echo $VERSION | cut -d. -f1)
printf '%s\n' "--gcc-toolchain=/opt/${GCC_DIR}" "-L/opt/${GCC_DIR}/lib" "-L/opt/${GCC_DIR}/lib64" "-Wl,-rpath,/opt/${GCC_DIR}/lib" "-Wl,-rpath,/opt/${GCC_DIR}/lib64" > /opt/clang-${VERSION}/bin/clang.cfg
ln -s clang.cfg /opt/clang-${VERSION}/bin/clang++.cfg
EOF

RUN chmod +x /tmp/build-clang.sh \
    && /tmp/build-clang.sh ${CLANG_VERSION} ${GCC_VERSION} \
    && rm /tmp/build-clang.sh

FROM couchbasebuild/dfs:20260323
ARG CLANG_VERSION
COPY --from=clang_build /opt/clang-${CLANG_VERSION} /opt/clang-${CLANG_VERSION}
