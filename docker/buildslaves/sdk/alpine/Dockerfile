# Docker container for Alpine

FROM alpine:3.14

ARG CMAKE_VERSION
ARG SWARM_CLIENT_VERSION
ARG GRADLE_VERSION
ARG MAVEN_VERSION

LABEL maintainer="build-team@couchbase.com"

ENV PATH="/usr/local/bin:${PATH}"

# Install Couchbase build dependencies
RUN apk add --no-cache \
        build-base \
        bzip2-dev \
        curl \
        gdb \
        git \
        gnupg \
        groff \
        icu-libs \
        libev-dev \
        libevent-dev \
        libffi-dev \
        libunwind \
        libuv-dev \
        libxml2-dev \
        musl-dbg \
        musl-locales \
        musl-locales-lang \
        oniguruma-dev \
        openjdk8 \
        openssh-client \
        openssl-dev \
        perl \
        python3-dev \
        py3-pip \
        py3-virtualenv \
        rsync \
        sudo \
        tar \
        unzip

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN set -x \
    && addgroup couchbase \
    && adduser couchbase -S -G couchbase \
    && addgroup couchbase wheel \
    && echo 'couchbase:couchbase' | chpasswd \
    && mkdir -p /opt/couchbase \
    && chown -R couchbase:couchbase /opt/couchbase \
    && sed -e 's;^# \(%wheel.*NOPASSWD.*\);\1;g' -i /etc/sudoers

# Ensure /opt/cbdeps is writable
RUN set -x \
    && mkdir /opt/cbdeps \
    && chown couchbase:couchbase /opt/cbdeps \
    && chmod 755 /opt/cbdeps

# Repo
RUN set -x \
    && curl -Lsf https://storage.googleapis.com/git-repo-downloads/repo \
            -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# CMake
RUN set -x \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -fLOs https://cmake.org/files/v$(echo ${CMAKE_VERSION} | awk 'BEGIN{FS=OFS="."} NF--')/cmake-${CMAKE_VERSION}.tar.gz \
    && tar -zxf cmake-${CMAKE_VERSION}.tar.gz \
    && cd cmake-${CMAKE_VERSION}/ \
    && ./bootstrap && make -j8 && make install \
    && rm -rf /tmp/deploy

# sbt
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing sbt

# Gradle + Maven
RUN set -x \
    && mkdir /tmp/deploy \
    && curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && curl -L -o /tmp/deploy/maven.zip http://apache.mirrors.tds.net/maven/maven-$(echo ${MAVEN_VERSION} | awk 'BEGIN{FS=OFS="."} NF=1')/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip \
    && cd /usr/local \
    && unzip /tmp/deploy/gradle.zip \
    && unzip /tmp/deploy/maven.zip \
    && ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin \
    && rm -rf /tmp/deploy

# libcouchbase
RUN set -x \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && git clone ssh://git@github.com/couchbase/libcouchbase.git \
    && cd libcouchbase && mkdir build && cd build \
    && ../cmake/configure \
    && make \
    && make install \
    && rm -rf /tmp/deploy

# Create python symlink
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set LANG
ENV LANG=en_US.UTF-8

# Temp install step for "cbdep" tool
ARG CACHEBUST=1
RUN curl https://s3.amazonaws.com/packages.couchbase.com/cbdep/cbdep-linux-x64-musl -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
USER couchbase
RUN mkdir /home/couchbase/.ssh

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
