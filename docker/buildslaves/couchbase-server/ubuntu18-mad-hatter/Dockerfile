# Docker container for Ubuntu 18.04

# This has to be first - define the GCC version to use and
# the image to pull it from
FROM couchbasebuild/server-ubuntu18-build:20200424

# Replace the JDK
RUN set -x \
    && apt-get update \
    && apt-get purge -y openjdk-8-jre-headless \
    && apt-get purge -y openjdk-11-jre-headless \
    && apt-get autoremove -y
ARG JRE_MAJOR
ARG JRE_VERSION
ARG JRE_BUILD
RUN set -x \
    && ARCH=$(uname -m | sed -e 's/86_//') \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -Lf https://github.com/adoptium/temurin${JRE_MAJOR}-binaries/releases/download/jdk-${JRE_VERSION}%2B${JRE_BUILD}/OpenJDK${JRE_MAJOR}U-jre_${ARCH}_linux_hotspot_${JRE_VERSION}_${JRE_BUILD}.tar.gz -o openjre.tar.gz \
    && cd /usr/local \
    && tar xvzf /tmp/deploy/openjre.tar.gz \
    && ln -s jdk* java \
    && for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done \
    && rm -rf /tmp/deploy

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.share

# Start script
COPY build/couchbuilder_start.sh /usr/sbin/

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
