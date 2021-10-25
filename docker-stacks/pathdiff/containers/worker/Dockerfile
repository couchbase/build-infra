FROM python:3-slim

ARG DOCKER_VERSION=20.10.6

# ENV PATH=/home/couchbase/.local/bin/:$PATH

RUN apt update && apt install -y curl file && apt clean

# Install docker static binary for running docker command-line
RUN set -x \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -o docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
    && tar xf docker.tgz \
    && cp -a docker/docker /usr/local/bin \
    && cd /tmp \
    && rm -rf deploy

COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip install -r requirements.txt

COPY . /app

# When doing local development, we do live reloading via watchdog
CMD [ "$dev" = "" ] \
    && celery -A worker worker --concurrency=1 \
    || watchmedo auto-restart -d /app -p '*.py' -- celery -A worker worker --concurrency=1 --loglevel=DEBUG
