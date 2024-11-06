# Dockerfile for Jenkins worker running black duck detect
FROM ubuntu:24.04

LABEL maintainer="Couchbase Build Team <build-team@couchbase.com>"

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
#
# Note: we do this prior to installing openjdk as openjdk depends on systemd
# which creates a `systemd-journal` group with gid 999 - by creating our docker
# group with gid 999 up front, a different gid will be used for systemd-journal
RUN set -x \
    && apt update \
    && apt install -y adduser sudo \
    && apt clean \
    && addgroup --gid 999 docker \
    && useradd couchbase -G sudo,docker -m -s /bin/bash \
    && mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase \
    && echo 'couchbase:couchbase' | chpasswd \
    && sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# tini, to avoid zombie issues when running with Swarm jar
ARG TINI_VER
ADD https://github.com/krallin/tini/releases/download/v${TINI_VER}/tini-amd64 /tini
RUN chmod +x /tini

# Basic reqs
RUN set -x \
    && apt update \
    && apt install -y \
        apt-transport-https \
        build-essential \
        curl \
        git \
        jq \
        libxml2-utils \
        openjdk-17-jre-headless \
        openjdk-17-jdk \
        openjdk-17-jdk-headless \
        python3 \
        python3-pip \
        python3-venv \
        rsync \
        ruby \
        ruby-dev \
        sudo \
        vim \
        wget \
    && ln -s /usr/bin/bundler3.2 /usr/local/bin/bundle \
    && apt clean

RUN set -x \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list \
    && apt update \
    && apt install -y docker-ce-cli \
    && apt clean

ARG YQ_VER
RUN set -x \
    && curl -Lfo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_amd64 \
    && chmod a+x /usr/local/bin/yq

RUN set -x \
    && curl -Lfo /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
    && sed -i 's/env python$/env python3/' /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# Jenkins bits
ARG JNLP_AGENT_VER
RUN set -x \
    && curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar \
        https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
    && chmod 755 /usr/share/jenkins \
    && chmod 644 /usr/share/jenkins/agent.jar \
    && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

# cbdep
RUN set -x \
    && curl -L -o /usr/local/bin/cbdep https://packages.couchbase.com/cbdep/cbdep-linux \
    && chmod 755 /usr/local/bin/cbdep

# UV for Jenkins scripts
ARG UV_VER
RUN set -x \
    && cd /tmp \
    && curl -L -o uv.tgz https://github.com/astral-sh/uv/releases/download/${UV_VER}/uv-x86_64-unknown-linux-gnu.tar.gz \
    && tar xf uv.tgz \
    && cp -a uv-*/* /usr/local/bin \
    && rm -rf uv*

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Expose SSH daemon and run our builder startup script
EXPOSE 22
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

USER couchbase

# Android SDK
ARG CMDTOOLS_LINUX_VERSION="7302050"
ENV ANDROID_SDK_HOME="/home/couchbase/tools/android-sdk"
ENV ANDROID_SDK_TOOLS="/home/couchbase/tools/android-sdk/cmdline-tools/latest"

RUN set -x \
    && mkdir -p "${ANDROID_SDK_TOOLS}" && cd "${ANDROID_SDK_TOOLS}" \
    && curl -Lfso ./tools.zip https://dl.google.com/android/repository/commandlinetools-linux-${CMDTOOLS_LINUX_VERSION}_latest.zip \
    && unzip tools.zip && rm tools.zip && mv cmdline-tools/* . \
    && ln -s "${ANDROID_SDK_TOOLS}" "${ANDROID_SDK_HOME}/tools" \
    && yes 'y' | "${ANDROID_SDK_HOME}/tools/bin/sdkmanager" --licenses >/dev/null

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
