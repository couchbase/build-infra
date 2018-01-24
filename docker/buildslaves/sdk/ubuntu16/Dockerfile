# Docker container for Ubuntu 16.04

FROM ubuntu:16.04
MAINTAINER build-team@couchbase.com

USER root

# Install Couchbase build dependencies
RUN apt-get update && \
    apt-get install -y binutils make software-properties-common python-setuptools \
                       python-dev python-pip git npm openjdk-8-jdk \
                       ccache g++ git-core tar ruby rake ed man curl && \
    apt-get install -y cmake pkg-config autoconf automake libtool sudo &&\
    apt-get clean

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

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
USER couchbase
RUN mkdir /home/couchbase/.ssh
