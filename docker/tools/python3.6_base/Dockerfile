# Docker base container for Python 3.6 on Ubuntu 16.04
#
# This is just a BASE container and should only be used to build upon
# for other containers

FROM ubuntu:16.04
MAINTAINER build-team@couchbase.com

USER root

# Install some core necessities
RUN apt-get update && \
    apt-get install -y build-essential curl git-core sudo && \
    apt-get clean

# Install CMake and repo (used by a number of tool images)
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v3.6/cmake-3.6.1-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo && \
    cd /tmp && rm -rf /tmp/deploy

# Create couchbase user with password-less sudo privs
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Install Python 3.6 and useful base tools; note that Python 3.6 requires
# the deadsnakes PPA repository, which requires the software-properties-
# common package.
# Also include Python 2.7, required by 'repo'. This needs to be available
# as "python" on PATH.
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python3.6-dev python3.6-venv tar python2.7 && \
    ln -s /usr/bin/python2.7 /usr/local/bin/python && \
    apt-get clean && \
    curl https://bootstrap.pypa.io/get-pip.py | sudo python3.6

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8

# Install libcouchbase (needed for Python Couchbase SDK)
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -O http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-4-amd64.deb && \
    dpkg -i couchbase-release-1.0-4-amd64.deb && \
    apt-get update && \
    apt-get install -y libcouchbase-dev libcouchbase2-bin && \
    cd /tmp && \
    rm -rf deploy && \
    rm -f /var/cache/apt/archives/*.deb

# Go ahead and install the Python Couchbase SDK, since many sub-images will
# use it
RUN pip3.6 install couchbase

ENV LANG=en_US.UTF-8
