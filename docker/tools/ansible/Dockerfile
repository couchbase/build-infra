# Dockerfile for building Ansible image for Ubuntu 16.04 (Xenial), with as few additional software as possible.
#
# @see https://launchpad.net/~ansible/+archive/ubuntu/ansible
#
# Version  1.0
#


# pull base image
FROM ubuntu:16.04

MAINTAINER Couchbase Build Team <build-team@couchbase.com>

RUN apt-get update                             && \
    apt-get install -y python-pip sshpass openssh-client && \
    apt-get clean
RUN pip install --upgrade ansible==2.4.1       && \
    pip install --upgrade pywinrm

ADD entrypoint.sh /
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "--version" ]
