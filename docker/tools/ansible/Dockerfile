# Dockerfile for building Ansible image, with as little additional software as possible.

# pull base image
FROM ubuntu:22.04

LABEL maintainer="Couchbase Build Team <build-team@couchbase.com>"

ARG ANSIBLE_VERSION

RUN set -x \
      && apt-get update \
      && apt-get install -y python-is-python3 python3-venv sshpass openssh-client rsync \
      && apt-get clean
RUN set -x \
      && python -m venv /venv \
      && . /venv/bin/activate \
      && pip install --upgrade pip \
      && pip install --upgrade ansible==${ANSIBLE_VERSION} \
      && pip install --upgrade pywinrm \
      && pip install --upgrade ansible-toolbox

ADD entrypoint.sh /
# Need to save this arg in an environment variable, because ENTRYPOINT
# arguments are evaluated at container run-time

ARG ANSIBLE_COMMAND
ENV ANSIBLE_COMMAND="${ANSIBLE_COMMAND}"
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "--version" ]
