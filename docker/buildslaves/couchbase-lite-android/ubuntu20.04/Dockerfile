# Docker container for Ubuntu 20.04

FROM  ubuntu:20.04
LABEL maintainer="build-team@couchbase.com"

USER root

# Install sudo first
RUN apt-get update && \
    apt-get install -y sudo && \
    apt-get clean

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Install tzdata
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

# Install Couchbase Lite Android toolchain requirements
RUN apt-get update && \
    apt-get install -y git-core tar curl unzip gcc-multilib g++-multilib lib32z1 lib32stdc++6 openjdk-17-jdk gnupg2 zip rsync wget && \
    apt-get clean

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8

#install Python 3
RUN set -x \
    && apt-get update \
    && apt-get -y install python3 python3-dev python3-venv python3-pip \
    && apt-get clean

# Set LANG
ENV LANG=en_US.UTF-8

# Android SDK
USER couchbase

# Download and untar Android CommandLine Tools under /home/couchbase/jenkins/tools/android-sdk/cmdline-tools/latest

ENV CMDTOOLS_LINUX_VERSION=11076708

RUN mkdir -p /home/couchbase/jenkins/tools/android-sdk && \
    cd /home/couchbase/jenkins/tools/android-sdk && \
    curl --fail https://dl.google.com/android/repository/commandlinetools-linux-${CMDTOOLS_LINUX_VERSION}_latest.zip -o commandlinetools.zip && \
    unzip commandlinetools.zip -d cmdline-tools  && \
    mv cmdline-tools/cmdline-tools cmdline-tools/latest && \
    rm commandlinetools.zip && \
    chown -R couchbase:couchbase /home/couchbase/jenkins/tools && \
    chmod 755 /home/couchbase/jenkins/tools/android-sdk

# Set environment variable
ENV ANDROID_HOME /home/couchbase/jenkins/tools/android-sdk
ENV PATH ${ANDROID_HOME}/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:${ANDROID_HOME}/tools/bin:$PATH
ENV SDK_CMD $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager

# Android SDK License
RUN yes 'y' | sdkmanager --licenses >/dev/null

# Update and install using sdkmanager
# CBD-4752, sdkmanager behavior changed.  "Tools" also installs "platform-tools"
# If "tools" and "platform-tools" are called at the same time, platform-tools will be installed into platform-tools-2
# If they are called separately, "platform-tools" will skip the installation if "platform-tools" directory exists
# Keep both target in case if the behavior changes again.

RUN $SDK_CMD "tools" && \
    $SDK_CMD "platform-tools" && \
    $SDK_CMD "extras;android;m2repository" "extras;google;m2repository"

# Also install maven.
RUN cd /home/couchbase/jenkins/tools && \
    curl --fail https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar xzf -

# Revert so CMD will run as root.
USER root

# CBD-4280: set openjdk-17-jdk as default
RUN update-java-alternatives -s java-1.17.0-openjdk-amd64

# Add cbdep tool
RUN curl --fail http://packages.couchbase.com/cbdep/cbdep-linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
