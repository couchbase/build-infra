FROM debian:11-slim
RUN apt-get update && apt-get install -y \
    clang-19 \
    curl \
    git \
    jq \
    make \
    openssh-client \
    openssh-server \
    patchelf \
    rsync \
    sudo \
    wget \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /var/run/sshd

RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang-19 100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++-19 100

# Install repo command
RUN curl -f https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Create couchbase user with password-less sudo privs
RUN groupadd -g 1000 couchbase && \
    useradd -m -g 1000 -s /bin/bash couchbase && \
    echo "couchbase ALL=(ALL:ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/couchbase && \
    chmod 0440 /etc/sudoers.d/couchbase

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# Install cbdep
RUN curl -Lf https://packages.couchbase.com/cbdep/cbdep-linux-$(uname -m) -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

# Create basic directories needed for jenkins
USER couchbase
RUN mkdir -p /home/couchbase/jenkins/workspace /home/couchbase/.cbdepscache /home/couchbase/.cbdepcache/ /home/couchbase/.ccache

USER root

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Use cbdep to install JVM for Jenkins.
ARG JDK_VERSION
RUN set -x \
    && cbdep install -d /usr/local openjdk ${JDK_VERSION} \
    && ln -s /usr/local/openjdk-${JDK_VERSION}/bin/java /usr/local/bin/java \
    && rm -rf /root/.cbdepcache /root/.local

# Use cbdep to install cmake
ARG CMAKE_VERSION
RUN cbdep install -d /usr/local cmake ${CMAKE_VERSION} \
    && ln -s /usr/local/cmake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/cmake

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}

USER couchbase

ADD --chmod=0755 https://cb-entry.s3.us-west-2.amazonaws.com/universal-entrypoint.sh /universal_entrypoint.sh
ENTRYPOINT ["/universal_entrypoint.sh"]
CMD []
