FROM couchbasebuild/sdk-debian8-build:20200813

# CMake
RUN mkdir /tmp/deploy && \
    curl -L https://cmake.org/files/v3.21/cmake-3.21.4-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm /usr/local/bin/cmake-gui && \
    rm -rf /tmp/deploy

COPY build/couchbuilder_start.sh /usr/sbin/
