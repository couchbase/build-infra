# This Dockerfile exists only to update the Jenkins Swarm jar in the
# existing Docker image. We don't want to rebuild some of the older
# historic images and risk raising unexpected issues when rebuilding
# older releases. The file Dockerfile.historic is the Dockerfile that
# the image was originally build from.

FROM couchbasebuild/server-suse11-build:20180713

ADD build/swarm-client-3.17.jar /usr/local/lib/swarm-client.jar

# Also need to update repo
ADD https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo /usr/local/bin/repo
RUN chmod a+x /usr/local/bin/repo

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