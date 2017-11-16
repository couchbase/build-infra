# Docker base container for Python 3.6 on Ubuntu 16.04
#
# This is just a BASE container and should only be used to build upon
# for other containers

FROM ubuntu:16.04
MAINTAINER build-team@couchbase.com

USER root

# Install sudo
RUN apt-get update && \
    apt-get install -y sudo && \
    apt-get clean

# Create couchbase user with password-less sudo privs
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Install Python 3.6 and useful base tools; note that Python 3.6 requires
# the fkrull/deadsnakes repository, which requires the software-properties-
# common package
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:fkrull/deadsnakes && \
    apt-get update && \
    apt-get install -y curl python3.6-dev python3.6-venv tar && \
    apt-get clean

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
