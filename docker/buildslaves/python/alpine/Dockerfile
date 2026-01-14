# Docker container for Python/Alpine

FROM python:3.9.10-alpine
LABEL maintainer="build-team@couchbase.com"

ARG SWARM_CLIENT_VERSION

RUN apk add --no-cache \
            bash \
            curl \
            git \
            gnupg \
            openssh-client \
            rsync \
            sudo

# JDK for Jenkins
RUN mkdir /tmp/deploy && \
cd /tmp/deploy && \
curl --fail -L https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jre_x64_alpine-linux_hotspot_21.0.5_11.tar.gz -o openjre.tar.gz && \
cd /usr/local && \
tar xvzf /tmp/deploy/openjre.tar.gz && \
ln -s jdk* java && \
for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
rm -rf /tmp/deploy

# cbdep build dependencies
RUN apk add --no-cache \
            build-base \
            libxml2-dev \
            libxslt-dev \
            zlib-dev

# Create couchbase user with password-less sudo privs
RUN set -x \
    && addgroup -g 1000 couchbase \
    && adduser couchbase -u 1000 -S -G couchbase \
    && addgroup couchbase wheel \
    && echo 'couchbase:couchbase' | chpasswd \
    && sed -e 's;^# \(%wheel.*NOPASSWD.*\);\1;g' -i /etc/sudoers

# repo
RUN set -x \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/bin/repo \
    && chmod a+rx /usr/bin/repo

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
