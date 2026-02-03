# Docker container for Debian 12

FROM debian:12
LABEL maintainer="build-team@couchbase.com"

USER root

# Install Couchbase build dependencies
RUN apt-get update && \
    apt-get install -y build-essential curl git libssl-dev lsb-release sudo tar && \
    apt-get install -y groff-base python3-dev python3-pip python3-virtualenv && \
    apt-get install -y libuv1-dev libev-dev libevent-dev zlib1g-dev libbz2-dev libffi-dev && \
    apt-get install -y libunwind8 libicu72 libssl3 ccache cmake ninja-build && \
    apt-get clean

# JDK for Jenkins
RUN mkdir /tmp/deploy && \
    curl --fail -L "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jre_x64_linux_hotspot_21.0.5_11.tar.gz" -o /tmp/deploy/openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Ensure /opt/cbdeps is writable
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# libcouchbase
RUN mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -LO https://packages.couchbase.com/clients/c/repos/deb/couchbase.key \
    && apt-key add couchbase.key \
    && echo "deb https://packages.couchbase.com/clients/c/repos/deb/debian12 bookworm bookworm/main" > /etc/apt/sources.list.d/libcouchbase.list \
    && apt update \
    && apt install libcouchbase3 libcouchbase-dev libcouchbase3-tools libcouchbase-dbg libcouchbase3-libev libcouchbase3-libevent

# Install uv and cbdep to /usr/local/bin
# And add /usr/local/bin/ to PATH
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh
RUN curl -Lf https://packages.couchbase.com/cbdep/cbdep-linux-$(uname -m) -o /usr/local/bin/cbdep \
    && chmod a+x /usr/local/bin/cbdep
RUN echo "/usr/local/bin" >> /etc/path

# Enable disk/memory healthchecks
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
USER couchbase
RUN mkdir /home/couchbase/.ssh

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
