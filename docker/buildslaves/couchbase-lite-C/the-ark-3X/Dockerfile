# Docker container for cross-compiling

FROM debian:buster
LABEL maintainer="build-team@couchbase.com"

RUN echo "deb http://archive.debian.org/debian buster main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main contrib non-free" >> /etc/apt/sources.list

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
    python3-pip \
    rsync \
    ruby \
    devscripts \
    g++-arm-linux-gnueabihf \
    g++-aarch64-linux-gnu \
    libicu-dev \
    zlib1g-dev \
&& rm -rf /var/lib/apt/lists

RUN pip3 install progressbar

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Install uv and install cbdep for `couchbase` user
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh
ENV PATH="/home/couchbase/.local/bin:${PATH}"
RUN echo -n ":/home/couchbase/.local/bin" >> /etc/path
USER couchbase
RUN uv tool install cbdep

# Use cbdep to install JVM for Jenkins
USER root
ARG JDK_VERSION=21.0.6+7
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
