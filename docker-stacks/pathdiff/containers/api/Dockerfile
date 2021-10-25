FROM python:3.9.7-buster

ARG DOCKER_VERSION=20.10.6

ENV PATH=/home/couchbase/.local/bin/:$PATH

RUN apt update && apt install -y curl gcc libmariadb3 libmariadb-dev && apt clean

# Create couchbase user
RUN set -x \
    && useradd couchbase -m -s /bin/bash \
    && echo 'couchbase:couchbase' | chpasswd

USER couchbase

COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt

COPY . /app

# we use watchdog to live reload only when developing locally
CMD [ "$dev" = "" ] \
    && python -u api.py \
    || watchmedo auto-restart --recursive --pattern="*.py" --directory="." python api.py

VOLUME /data
