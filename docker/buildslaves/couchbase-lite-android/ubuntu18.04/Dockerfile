# Docker container for Ubuntu 18.04

FROM  ubuntu:18.04
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

# Install Couchbase Lite Android toolchain requirements
RUN apt-get update && \
    apt-get install -y git-core tar curl unzip gcc-multilib g++-multilib lib32z1 lib32stdc++6 openjdk-11-jdk gnupg2 zip rsync wget && \
    apt-get clean

# Swarm client jar - only needed until CBD-4101 is resolved
RUN curl --fail \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.25/swarm-client-3.25.jar \
    -o /usr/local/lib/swarm-client.jar

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8

#install Python 3.7.7
RUN set -x \
    && apt-get update \
    && apt-get -y install python3.7 python3.7-dev python3-venv python3.7-venv python3-pip \
    && apt-get clean

#set python3.7 as default python3 instead of python3.6
RUN rm -f /usr/bin/python3 \
    && ln -s /usr/bin/python3.7 /usr/bin/python3

# Set LANG
ENV LANG=en_US.UTF-8

# Android SDK
USER couchbase

# Download and untar Android CommandLine Tools
# It is a little messy.  It needs to go under /home/couchbase/jenkins/tools/android-sdk/cmdline-tools/latest

ENV CMDTOOLS_LINUX_VERSION=7302050

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
RUN $SDK_CMD "tools" "platform-tools" && \
    $SDK_CMD "build-tools;28.0.3" && \
    $SDK_CMD "build-tools;29.0.0" && \
    $SDK_CMD "build-tools;29.0.2" && \
    $SDK_CMD "platforms;android-29" && \
    $SDK_CMD "extras;android;m2repository" "extras;google;m2repository" && \
    $SDK_CMD "cmake;3.10.2.4988404"

# Also install maven.
RUN cd /home/couchbase/jenkins/tools && \
    curl --fail https://archive.apache.org/dist/maven/maven-3/3.8.1/binaries/apache-maven-3.8.1-bin.tar.gz | tar xzf -

# Revert so CMD will run as root.
USER root

# CBD-4280: set openjdk-11-jdk as default
RUN update-java-alternatives -s java-1.11.0-openjdk-amd64

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
