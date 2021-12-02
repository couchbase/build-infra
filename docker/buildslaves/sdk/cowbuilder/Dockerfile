
# Docker container for Debian - testing tag is used for debootstrap freshness
FROM debian:testing-20200720-slim
LABEL maintainer="build-team@couchbase.com"
ENV LANG=en_US.UTF-8

USER root

# Update locale
RUN set -x \
        && apt-get update \
        && apt-get install -y locales \
        && apt-get clean \
        && locale-gen en_US.UTF-8

# Install basic slave dependencies
RUN set -x \
        && apt-get update \
        && mkdir -p /usr/share/man/man1 \
        && apt-get install -y build-essential \
                              cmake \
                              cowbuilder \
                              curl \
                              devscripts \
                              git \
                              lsb-release \
                              openjdk-11-jdk-headless \
                              reprepro \
                              sudo \
                              tar \
        && apt-get clean

# Install ubuntu-archive-keyring - not presently available in the testing package repository
RUN set -x \
        && cp /etc/apt/sources.list /tmp/sources.list \
        && echo "deb http://deb.debian.org/debian buster main" >> /etc/apt/sources.list \
        && apt update \
        && apt install -y ubuntu-archive-keyring \
        && mv /tmp/sources.list /etc/apt \
        && apt update \
        && apt clean

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

COPY pbuilderrc /etc/pbuilderrc

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
