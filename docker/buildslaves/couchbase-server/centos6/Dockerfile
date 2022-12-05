# This Dockerfile exists only to update the Jenkins Swarm jar in the
# existing Docker image. We don't want to rebuild some of the older
# historic images and risk raising unexpected issues when rebuilding
# older releases. The file Dockerfile.historic is the Dockerfile that
# the image was originally build from.

FROM couchbasebuild/server-centos6-build:20181218

RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.17/swarm-client-3.17.jar \
    -o /usr/local/lib/swarm-client.jar

RUN set -x \
        && curl --fail -Lo "/usr/bin/rsync" https://github.com/JBBgameich/rsync-static/releases/download/continuous/rsync-x86 \
        && chmod a+x /usr/bin/rsync

RUN set -x \
  && mkdir /tmp/deploy \
  && cd /tmp/deploy \
  && curl -L https://repo.anaconda.com/miniconda/Miniconda2-4.7.12.1-Linux-x86_64.sh -o miniconda2.sh \
  && chmod 755 miniconda2.sh \
  && ./miniconda2.sh -b -f -p /home/couchbase/miniconda2 \
  && cd /tmp \
  && rm -rf deploy

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

# JRE for Jenkins.
RUN yum remove -y java-1.8.0-openjdk-headless
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

ENV AGENT_VERSION=4.3

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

RUN rm -rf /home/couchbase/.ssh

COPY build/couchbuilder_start.sh /usr/sbin/
