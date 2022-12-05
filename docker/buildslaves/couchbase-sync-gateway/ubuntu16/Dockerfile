# This Dockerfile exists only to update the JRE in the existing Docker
# image. We don't want to rebuild some of the older historic images and
# risk raising unexpected issues when rebuilding older releases. The
# file Dockerfile.historic is the Dockerfile that the image was
# originally build from.

FROM couchbasebuild/ubuntu1604-sgw-build:20181204

# JRE for Jenkins.
RUN set -x \
    && apt-get purge -y openjdk-8-jre-headless \
    && apt-get autoremove -y \
    && ARCH=$(uname -m | sed -e 's/86_//') \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -Lf https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.5%2B8/OpenJDK17U-jre_${ARCH}_linux_hotspot_17.0.5_8.tar.gz -o openjre.tar.gz \
    && cd /usr/local \
    && tar xvzf /tmp/deploy/openjre.tar.gz \
    && ln -s jdk* java \
    && for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done \
    && rm -rf /tmp/deploy
