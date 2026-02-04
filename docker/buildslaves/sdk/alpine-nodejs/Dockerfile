# Docker container for Alpine

ARG ALPINE_IMAGE

FROM ${ALPINE_IMAGE}

ARG CMAKE_VERSION
ARG GRADLE_VERSION
ARG MAVEN_VERSION
ARG SBT_VERSION

LABEL maintainer="build-team@couchbase.com"

ENV PATH="/usr/local/bin:${PATH}"

# Install Couchbase build dependencies
RUN apk add --no-cache \
        abuild \
        alpine-sdk \
        bash \
        build-base \
        bzip2-dev \
        ccache \
        cmake \
        curl \
        gdb \
        git \
        gnupg \
        go \
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
        openssh \
        openssl-dev \
        perl \
        python3-dev \
        py3-pip \
        py3-virtualenv \
        rsync \
        sudo \
        tar \
        unzip

# JDK for Jenkins
RUN mkdir /tmp/deploy && \
cd /tmp/deploy && \
case "$(uname -m)" in \
    x86_64) JDK_ARCH="x64" ;; \
    aarch64) JDK_ARCH="aarch64" ;; \
    *) echo "Unsupported architecture: $(uname -m)" && exit 1 ;; \
esac && \
curl --fail -L "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jre_${JDK_ARCH}_alpine-linux_hotspot_21.0.5_11.tar.gz" -o openjre.tar.gz && \
cd /usr/local && \
tar xvzf /tmp/deploy/openjre.tar.gz && \
ln -s jdk* java && \
for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
rm -rf /tmp/deploy

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN set -x \
    && addgroup -g 1001 couchbase \
    && adduser -D -u 1001 couchbase -G couchbase \
    && chmod 755 /home/couchbase \
    && mkdir /home/couchbase/.ssh /home/couchbase/.docker \
    && chown -R couchbase:couchbase /home/couchbase \
    && addgroup couchbase wheel \
    && addgroup couchbase abuild \
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

# sbt
RUN set -x \
    && cd /tmp \
    && mkdir /usr/local/sbt \
    && curl -LO https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz \
    && tar xf sbt-${SBT_VERSION}.tgz --strip-components=1 -C /usr/local/sbt \
    && ln -s /usr/local/sbt/bin/* /usr/local/bin

# Gradle + Maven
RUN set -x \
    && mkdir /tmp/deploy \
    && curl -L -o /tmp/deploy/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
    && curl -L -o /tmp/deploy/maven.zip https://archive.apache.org/dist/maven/maven-$(echo ${MAVEN_VERSION} | awk 'BEGIN{FS=OFS="."} NF=1')/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.zip \
    && cd /usr/local \
    && unzip /tmp/deploy/gradle.zip \
    && unzip /tmp/deploy/maven.zip \
    && ln -s /usr/local/apache-maven-*/bin/mvn /usr/local/gradle-*/bin/gradle /usr/local/bin \
    && rm -rf /tmp/deploy

# libcouchbase
RUN set -x \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && git clone https://github.com/couchbase/libcouchbase.git \
    && cd libcouchbase && mkdir build && cd build \
    && ../cmake/configure \
    && make -j8 \
    && make install \
    && rm -rf /tmp/deploy

# add OpenSSL 1.1.1
ARG openssl_version=1.1.1w
ARG openssl_install_dir=/opt/openssl-$openssl_version
RUN cd /tmp && \
    curl -L -o openssl-$openssl_version.tar.gz https://www.openssl.org/source/openssl-$openssl_version.tar.gz && \
    tar -xzf openssl-$openssl_version.tar.gz && \
    cd openssl-$openssl_version && \
    ./config --prefix=$openssl_install_dir --openssldir=$openssl_install_dir shared zlib-dynamic && \
    make -j4 && \
    make install_sw install_ssldirs && \
    rm -rf /tmp/openssl-$openssl_version && \
    rm -f /tmp/openssl-$openssl_version.tar.gz

# Set LANG
ENV LANG=en_US.UTF-8

# Install uv and cbdep to /usr/local/bin
# And add /usr/local/bin/ to PATH
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh
RUN curl -Lf https://packages.couchbase.com/cbdep/cbdep-linux-$(uname -m) -o /usr/local/bin/cbdep \
    && chmod a+x /usr/local/bin/cbdep
RUN echo "/usr/local/bin" >> /etc/path

# Enable disk/memory healthchecks
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
