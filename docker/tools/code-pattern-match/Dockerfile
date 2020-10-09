FROM ubuntu:20.04
LABEL maintainer="build-team@couchbase.com"

ENV DENO_INSTALL="/$HOME/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"

RUN set -x \
        && apt update \
        && apt install -y curl git gpg python3 unzip silversearcher-ag \
        && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
        && apt clean

RUN set -x \
        && curl -o /usr/local/bin/repo -L https://storage.googleapis.com/git-repo-downloads/repo \
        && chmod a+rx /usr/local/bin/repo

RUN set -x \
        && git config --global user.email "build-team@couchbase.com" \
        && git config --global user.name "Couchbase Build Team" \
        && git config --global color.ui false

RUN set -x \
        && mkdir /root/.ssh \
        && ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN set -x \
        && apt update \
        && apt install -y locales \
        && apt clean \
        && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8

RUN set -x \
        && curl -fsSL https://deno.land/x/install/install.sh | sh

COPY scripts/find-patterns.js /usr/local/bin/find-patterns
COPY scripts/entrypoint.sh /
COPY patterns.json /

RUN find-patterns /tmp &>/dev/null

WORKDIR /code

ENTRYPOINT [ "/entrypoint.sh" ]
