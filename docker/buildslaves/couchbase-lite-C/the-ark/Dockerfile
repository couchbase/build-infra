# Docker container for cross-compiling

FROM ubuntu:22.04
LABEL maintainer="build-team@couchbase.com"

# The cross compilers installed here are used for generic OS (like Ubuntu Core)
# Model specific cross compilation toolchains, such as Raspberry Pi, will be
# acquired dynamically in a running container.
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    jq \
    git \
    sudo \
    curl \
    make \
    python3 \
    python3-progressbar \
    rsync \
    ruby \
    devscripts \
    libicu-dev \
    zlib1g-dev \
&& rm -rf /var/lib/apt/lists

# CMake
ARG CMAKE_MAJOR=3
ARG CMAKE_MINOR=20
ARG CMAKE_PATCH=1
RUN mkdir /tmp/deploy && \
    curl -f https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && rm -rf /tmp/deploy

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -Lf https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.17%2B8/OpenJDK11U-jre_x64_linux_hotspot_11.0.17_8.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
