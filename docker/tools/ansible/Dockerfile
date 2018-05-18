# Dockerfile for building Ansible image for Ubuntu 16.04 (Xenial), with as few additional software as possible.
#
# @see https://launchpad.net/~ansible/+archive/ubuntu/ansible
#
# Version  1.0
#


# pull base image
FROM ubuntu:16.04

MAINTAINER Couchbase Build Team <build-team@couchbase.com>

ARG ANSIBLE_COMMAND
ARG ANSIBLE_VERSION

RUN apt-get update                                       && \
    apt-get install -y python-pip sshpass openssh-client && \
    apt-get clean
RUN pip install --upgrade ansible==${ANSIBLE_VERSION}   && \
    pip install --upgrade pywinrm

ADD entrypoint.sh /
# Need to save this arg in an environment variable, because ENTRYPOINT
# arguments are evaluated at container run-time
ENV ANSIBLE_COMMAND="${ANSIBLE_COMMAND}"
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "--version" ]
