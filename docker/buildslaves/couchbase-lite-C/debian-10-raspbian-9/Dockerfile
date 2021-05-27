# Docker container for cross-compiling to Raspbian 9 (Stretch)
# Note that this requires access to internal network resources to build

FROM debian:buster
MAINTAINER build-team@couchbase.com

RUN apt-get update && apt-get install -y \
    unzip \
    wget \
    git \
    cmake \
    sudo \
    curl \
&& rm -rf /var/lib/apt/lists

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

RUN wget https://sourceforge.net/projects/raspberry-pi-cross-compilers/files/Raspberry%20Pi%20GCC%20Cross-Compiler%20Toolchains/Stretch/GCC%209.3.0/Raspberry%20Pi%202%2C%203/cross-gcc-9.3.0-pi_2-3.tar.gz/download -O /tmp/cross-gcc.tar.gz \
    && wget http://downloads.build.couchbase.com/mobile/sysroot/sysroot-raspbian-stretch.zip -O /tmp/sysroot.zip

RUN mkdir -p /opt/pi-sysroot \
    && mkdir -p opt/pi-gcc \
    && unzip /tmp/sysroot.zip -d opt/pi-sysroot \
    && tar xvf /tmp/cross-gcc.tar.gz -C opt/pi-gcc \
    && mv opt/pi-gcc/**/* opt/pi-gcc \
    && rm /tmp/cross-gcc.tar.gz \
    && rm /tmp/sysroot.zip

ENV PATH="/opt/pi-gcc/bin:${PATH}" RASPBIAN_ROOTFS=/opt/pi-sysroot

# Add rsync for pulling config+secrets at startup
RUN set -x \
        && apt update \
        && apt install -y rsync \
        && apt clean

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
