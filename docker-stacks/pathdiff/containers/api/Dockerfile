FROM python:3-bookworm

ARG DOCKER_VERSION=27.5.1

ENV PATH=/home/couchbase/.local/bin/:$PATH

RUN apt update && apt install -y curl gcc libmariadb3 libmariadb-dev libmariadb-dev-compat && apt clean
RUN ln -s /usr/bin/mariadb_config /usr/local/bin/mariadb_config

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
