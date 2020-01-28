# Dockerfile for building Ansible image, with as little additional software as possible.

# pull base image
FROM ubuntu:18.04

MAINTAINER Couchbase Build Team <build-team@couchbase.com>

ARG ANSIBLE_VERSION

RUN apt-get update                                       && \
    apt-get install -y python-pip sshpass openssh-client rsync && \
    apt-get clean
RUN pip install --upgrade ansible==${ANSIBLE_VERSION}   && \
    pip install --upgrade pywinrm

ADD entrypoint.sh /
# Need to save this arg in an environment variable, because ENTRYPOINT
# arguments are evaluated at container run-time

ARG ANSIBLE_COMMAND
ENV ANSIBLE_COMMAND="${ANSIBLE_COMMAND}"
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "--version" ]
