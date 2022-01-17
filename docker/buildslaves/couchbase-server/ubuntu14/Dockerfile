# This Dockerfile exists only to update certain utilities in the
# existing Docker image. We don't want to rebuild some of the older
# historic images and risk raising unexpected issues when rebuilding
# older releases. The file Dockerfile.historic is the Dockerfile that
# the image was originally build from.

FROM couchbasebuild/server-ubuntu14-build:20180829

RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

RUN set -x \
        && apt-get update \
        && apt-get install rsync \
        && apt-get clean

# OpenSSH
ARG OPENSSH_VER
RUN set -x \
    && mkdir -p /tmp/src \
    && cd /tmp/src \
    && curl --fail -LO https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VER}.tar.gz \
    && tar --strip-components=1 -xvf openssh-${OPENSSH_VER}.tar.gz \
    && rm -f openssh-${OPENSSH_VER}.tar.gz \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && rm -rf /tmp/src

RUN rm -rf /home/couchbase/.ssh

COPY build/couchbuilder_start.sh /usr/sbin/