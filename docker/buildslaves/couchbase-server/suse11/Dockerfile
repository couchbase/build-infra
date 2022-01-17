# This Dockerfile exists only to update certain utilities in the
# existing Docker image. We don't want to rebuild some of the older
# historic images and risk raising unexpected issues when rebuilding
# older releases. The file Dockerfile.historic is the Dockerfile that
# the image was originally build from.

FROM couchbasebuild/server-suse11-build:20180713

ADD https://storage.googleapis.com/git-repo-downloads/repo /usr/local/bin/repo
RUN chmod a+x /usr/local/bin/repo

# OpenSSL
ARG OPENSSL_VER
ADD build/openssl-${OPENSSL_VER}.tar.gz /opt/src
RUN set -x \
    && cd /opt/src/openssl-${OPENSSL_VER} \
    && ./config --prefix=/usr \
    && make \
    && make install \
    && rm -rf /opt/src/openssl-${OPENSSL_VER}

# OpenSSH
ARG OPENSSH_VER
ADD build/openssh-${OPENSSH_VER}.tar.gz /opt/src
RUN set -x \
    && cd /opt/src/openssh-${OPENSSH_VER} \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && rm -rf /opt/src/openssh-${OPENSSH_VER}

RUN zypper install -y rsync && zypper clean

RUN rm -rf /home/couchbase/.ssh

ENV AGENT_VERSION=4.3

ADD http://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar /usr/share/jenkins/agent.jar
RUN chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

COPY build/couchbuilder_start.sh /usr/sbin/