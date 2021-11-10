# Docker container for Python/Alpine

FROM python:3.9.6-alpine
LABEL maintainer="build-team@couchbase.com"

ARG SWARM_CLIENT_VERSION

RUN apk add --no-cache \
            bash \
            curl \
            git \
            gnupg \
            openjdk11 \
            openssh-client \
            rsync \
            sudo

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

# Jenkins Swarm client jar
RUN curl -Lfs https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VERSION}/swarm-client-${SWARM_CLIENT_VERSION}.jar -o /usr/local/lib/swarm-client.jar

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
