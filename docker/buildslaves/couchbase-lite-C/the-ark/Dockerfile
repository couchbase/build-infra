# Docker container for cross-compiling

FROM debian:bullseye
LABEL maintainer="build-team@couchbase.com"

# The cross compilers installed here are used for generic OS (like Ubuntu Core)
# Model specific cross compilation toolchains, such as Raspberry Pi, will be
# acquired dynamically in a running container.
# clang-16 implicitly installs llvm-16, so it is not needed here
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
    clang-16 \
    lld \
    ninja-build \
&& rm -rf /var/lib/apt/lists

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Install uv and cbdep for `couchbase` user
ENV PATH="/home/couchbase/.local/bin:${PATH}"
RUN echo -n ":/home/couchbase/.local/bin" >> /etc/path
USER couchbase
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN uv tool install cbdep

# Use cbdep to install JVM for Jenkins
USER root
ARG JDK_VERSION=17.0.15+6
RUN cbdep install -d /usr/local openjdk ${JDK_VERSION} \
    && ln -s /usr/local/openjdk-${JDK_VERSION}/bin/java /usr/local/bin/java

# Use cbdep to install cmake
ARG CMAKE_VERSION=3.31.7
RUN cbdep install -d /usr/local cmake ${CMAKE_VERSION} \
    && ln -s /usr/local/cmake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/cmake

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
