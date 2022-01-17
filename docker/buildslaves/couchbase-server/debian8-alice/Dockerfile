# This Dockerfile exists only to update the repo tool from the older
# image. We don't want to rebuild some of the older historic images and
# risk raising unexpected issues when rebuilding older releases.

FROM couchbasebuild/server-debian8-build:20201214

RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

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