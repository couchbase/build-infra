# Docker container for Ubuntu 18.04

FROM ubuntu:18.04
LABEL maintainer=build-team@couchbase.com

# Install rsync, SSH server, sudo
RUN apt-get update && \
    apt-get install -y openssh-server rsync sudo && \
    apt-get clean && \
    mkdir /var/run/sshd

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Add git-core PPA for newer git
RUN set -x \
    && apt-get update \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:git-core/ppa \
    && apt-get clean

# Install Couchbase build dependencies
RUN set -x \
    && apt update \
    && apt install -y \
        binutils \
        ccache \
        curl \
        debhelper \
        devscripts \
        ed \
        g++ \
        git \
        libssl-dev \
        man \
        ncurses-dev \
        python3 \
        python3-pip \
        rake \
        ruby \
    && ( [ "$(uname -m)" = "x86_64" ] && apt install -y libc6-i386 || :) \
    && apt clean

RUN echo 'PATH="/usr/lib/ccache:$PATH"' >> /home/couchbase/.profile
RUN set -x \
    && curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# Making python3 as default
RUN set -x \
    && ln -s /usr/bin/python3 /usr/bin/python

# PyInstaller is required by sgcollect_info
RUN pip3 install -Iv PyInstaller==3.1

# golang (install a current default, specific version should be in Jenkins's job)
RUN set -x \
    && mkdir -p /usr/local/go/1.19 && cd /usr/local/go/1.19 \
    && curl -fL -o go.tar.gz https://go.dev/dl/go1.19.linux-$([ "$(uname -m)" == "x86_64" ] && printf amd64 || printf arm64).tar.gz \
    && tar xf go.tar.gz \
    && rm go.tar.gz

# JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl --fail -L https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jre_x64_linux_hotspot_21.0.5_11.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

# Update locale
RUN set -x \
    && apt-get update \
    && apt-get install -y locales \
    && apt-get clean \
    && locale-gen en_US.UTF-8

# Swarm client jar
RUN curl --fail \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.36/swarm-client-3.36.jar \
    -o /usr/local/lib/swarm-client.jar

# Enable health checks
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Copy swarm properties
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /

ENV LANG=en_US.UTF-8

# Expose SSH daemon and run our builder startup script
EXPOSE 22
COPY --chown=couchbase:couchbase .ssh /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
