# Docker container for cross-compiling to Raspbian 9 (Stretch)
# Note that this requires access to internal network resources to build

FROM debian:buster
MAINTAINER build-team@couchbase.com

# The cross compilers installed here are used for generic OS (like Ubuntu Core)
# Model specific cross compilation toolchains, such as Raspberry Pi, will be
# acquired dynamically in a running container.
RUN apt-get update && apt-get install -y \
    unzip \
    wget \
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

# Install cmake from source
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

# Jenkins Swarm jar and JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -Lf https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11/OpenJDK11U-jre_x64_linux_hotspot_11.0.4_11.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

RUN curl -f \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.17/swarm-client-3.17.jar \
    -o /usr/local/lib/swarm-client.jar

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
