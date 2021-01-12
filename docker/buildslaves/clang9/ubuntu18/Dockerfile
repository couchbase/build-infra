FROM couchbasebuild/server-ubuntu18-build:20210112

LABEL maintainer="build-team@couchbase.com"

RUN set -x \
        && apt update \
        && apt install apt-transport-https \
        && apt clean

RUN set -x \
        && wget -qO- http://llvm.org/apt/llvm-snapshot.gpg.key | sudo apt-key add - \
        && echo "deb https://apt.llvm.org/bionic llvm-toolchain-bionic-9 main" > /etc/apt/sources.list.d/llvm.list \
        && apt update \
        && apt install -y \
            clang-9 \
            clang-format-9 \
            clang-tidy-9 \
            clang-tools-9 \
        && apt clean

# Create symlinks so clang picks up gcc 7.3.0 and associated libraries
RUN set -x \
        && mkdir -p /usr/local/include/x86_64-linux-gnu/c++ \
        && ln -s /usr/local/lib/gcc/x86_64-pc-linux-gnu/7.3.0 /usr/lib/gcc/x86_64-linux-gnu \
        && ln -s /usr/local/include/c++/7.3.0/x86_64-pc-linux-gnu /usr/local/include/x86_64-linux-gnu/c++/7.3.0

RUN set -x \
        && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-9 100 \
        && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-9 100
