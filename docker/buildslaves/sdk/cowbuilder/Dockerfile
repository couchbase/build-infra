
# Docker container for Debian - testing tag is used for debootstrap freshness
FROM debian:testing-20240211-slim
LABEL maintainer="build-team@couchbase.com"
ENV LANG=en_US.UTF-8

USER root

# Update locale
RUN set -x \
        && apt-get update \
        && apt-get install -y locales \
        && apt-get clean \
        && locale-gen en_US.UTF-8

COPY pbuilderrc /etc/pbuilderrc

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
                              openjdk-17-jre-headless \
                              reprepro \
                              sudo \
                              tar \
                              zstd \
                              ubuntu-archive-keyring \
        && apt-get clean

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

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
