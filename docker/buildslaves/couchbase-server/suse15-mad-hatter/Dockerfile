# Docker container for SUSE 15, based on openSUSE LEAP

FROM couchbasebuild/server-suse15-build:20200424
LABEL maintainer="build-team@couchbase.com"

# JRE for Jenkins.
ARG JRE_MAJOR
ARG JRE_VERSION
ARG JRE_BUILD
RUN set -x \
    && zypper remove -y javapackages-tools java-1_8_0-openjdk-headless \
    && ARCH=$(uname -m | sed -e 's/86_//') \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -Lf https://github.com/adoptium/temurin${JRE_MAJOR}-binaries/releases/download/jdk-${JRE_VERSION}%2B${JRE_BUILD}/OpenJDK${JRE_MAJOR}U-jre_${ARCH}_linux_hotspot_${JRE_VERSION}_${JRE_BUILD}.tar.gz -o openjre.tar.gz \
    && cd /usr/local \
    && tar xvzf /tmp/deploy/openjre.tar.gz \
    && ln -s jdk* java \
    && for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done \
    && rm -rf /tmp/deploy

# Ensure disk-checking healthcheck up to date
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Copy startup script
COPY build/couchbuilder_start.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
