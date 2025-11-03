# CV container based on linux-dfs

FROM couchbasebuild/server-builder:20250926 AS base
LABEL maintainer="build-team@couchbase.com"

USER root

# Various args and things that are used in all child stages
ARG GNU_MIRROR=https://mirrors.ocf.berkeley.edu/gnu
ARG tmpsrc=/tmp/deploy
ARG PARALLELISM=8
WORKDIR ${tmpsrc}

FROM base AS gdb_build
ARG GDB_VERSION

# GDB is required, amongst other things, for tests that ensure that
# crash minidump files are readable. It would be quite bad to discover
# that we were unable to load a crash minidump file from a customer.

RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -L ${GNU_MIRROR}/gdb/gdb-${GDB_VERSION}.tar.xz | tar -xJf - --strip-components=1 \
    && cd ${tmpsrc} \
    && ./configure --prefix=/opt/gdb --with-system-readline --with-system-zlib \
    && make -j${PARALLELISM} \
    && make install

FROM base AS clang_build
ARG CLANG_VERSION

# Clang is used by a variety of KV and Magma tests.

# Don't use tmpfs for this - it's too big. Use regular disk space.
RUN set -x \
    && curl -L https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-${CLANG_VERSION}.tar.gz | tar -xzf - --strip-components=1 \
    && cmake -S llvm -B build -G Ninja \
        -DLLVM_ENABLE_PROJECTS="clang" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/clang-${CLANG_VERSION} \
        -DLLVM_PARALLEL_LINK_JOBS=3 \
        -DLLVM_INCLUDE_TESTS=Off \
        -DCLANG_INCLUDE_TESTS=Off \
        -DLLVM_INCLUDE_EXAMPLES=Off \
        -DCLANG_BUILD_EXAMPLES=Off \
        -DCLANG_INCLUDE_DOCS=Off \
        -DLLVM_BUILD_DOCS=Off \
    && cmake --build build -j${PARALLELISM} \
    && cmake --install build \
    && rm -rf /tmp/deploy

FROM base AS final

# wget isn't really necessary since we have curl, but a number of tests
# and scripts assume wget is there
ARG WGET_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -L ${GNU_MIRROR}/wget/wget-${WGET_VERSION}.tar.gz | tar -xzf - --strip-components=1 \
    && cd ${tmpsrc} \
    && ./configure --prefix=/usr      \
            --sysconfdir=/etc  \
            --with-ssl=openssl \
    && make -j${PARALLELISM} \
    && make install

# aspell is used by "backup"'s tests, including Jenkinsfile
ARG ASPELL_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -L ${GNU_MIRROR}/aspell/aspell-${ASPELL_VERSION}.tar.gz | tar -xzf - --strip-components=1 \
    && ./configure --prefix=/usr \
    && make -j${PARALLELISM} \
    && make install
ARG ASPELL_DICT_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -L ${GNU_MIRROR}/aspell/dict/en/aspell6-en-${ASPELL_DICT_VERSION}.tar.bz2 | tar -xjf - --strip-components=1 \
    && ./configure \
    && make -j${PARALLELISM} \
    && make install

# xmlsec1 is required by pysaml2, which is used by ns_server cluster_tests
ARG XMLSEC_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -L https://github.com/lsh123/xmlsec/releases/download/${XMLSEC_VERSION}/xmlsec1-${XMLSEC_VERSION}.tar.gz | tar -xzf - --strip-components=1 \
    && ./configure --prefix=/usr \
    && make -j${PARALLELISM} \
    && make install

COPY --from=gdb_build /opt/gdb /opt/gdb
ENV PATH=/opt/gdb/bin:$PATH
RUN echo -n ":/opt/gdb/bin" >> /etc/path

ARG CLANG_VERSION
COPY --from=clang_build /opt/clang-${CLANG_VERSION} /opt/clang-${CLANG_VERSION}
ENV PATH=/opt/clang-${CLANG_VERSION}/bin:$PATH
RUN echo -n ":/opt/clang-${CLANG_VERSION}/bin" >> /etc/path

USER couchbase
WORKDIR /home/couchbase

# gcovr is used by some kv_engine and magma coverage tests
ARG GCOVR_VERSION
RUN uv tool install gcovr==${GCOVR_VERSION}

# ENV vars for profile data retrieval
ENV NODE_CLASS=cv
ENV NODE_PRODUCT=couchbase-server

# Enable .gitconfig so repo doesn't get whiny
COPY --chown=couchbase:couchbase build/gitconfig /home/couchbase/.gitconfig

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
