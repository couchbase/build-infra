# Docker container for build database REST API

FROM ubuntu:24.04
LABEL maintainer="build-team@couchbase.com"

# Ubuntu 24 has a default 'ubuntu' user with UID/GID 1000, which we want
# to be 'couchbase'. Fix that up.
RUN set -x \
    && apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates git \
    && apt-get clean \
    && groupmod --new-name couchbase ubuntu \
    && usermod --login couchbase -d /home/couchbase -m \
           -g couchbase -s /bin/bash ubuntu \
    && echo 'couchbase:couchbase' | chpasswd

COPY scripts/builddb_rest_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/builddb_rest_start.sh" ]
CMD [ "default" ]

# Install uv
ENV PATH=/root/.local/bin:$PATH
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Copy in application
COPY . /home/couchbase/builddb_rest
WORKDIR /home/couchbase/builddb_rest
RUN uv build
