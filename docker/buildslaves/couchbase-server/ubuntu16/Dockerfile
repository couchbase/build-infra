# This Dockerfile exists only to update the JRE in the existing Docker
# image. We don't want to rebuild some of the older historic images and
# risk raising unexpected issues when rebuilding older releases. Also,
# the deadsnakes repository stopped supporting Ubuntu 16.04, so we can't
# build the original image anymore. The file Dockerfile.historic is the
# Dockerfile that the image was originally build from.

FROM couchbasebuild/server-ubuntu16-build:20220114

# JRE for Jenkins.
ARG JRE_MAJOR
ARG JRE_VERSION
ARG JRE_BUILD
RUN set -x \
    && apt-get purge -y openjdk-8-jre-headless \
    && apt-get autoremove -y \
    && ARCH=$(uname -m | sed -e 's/86_//') \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -Lf https://github.com/adoptium/temurin${JRE_MAJOR}-binaries/releases/download/jdk-${JRE_VERSION}%2B${JRE_BUILD}/OpenJDK${JRE_MAJOR}U-jre_${ARCH}_linux_hotspot_${JRE_VERSION}_${JRE_BUILD}.tar.gz -o openjre.tar.gz \
    && cd /usr/local \
    && tar xvzf /tmp/deploy/openjre.tar.gz \
    && ln -s jdk* java \
    && for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done \
    && rm -rf /tmp/deploy
