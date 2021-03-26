FROM couchbasebuild/server-centos8-build:20200424

# rpm database in the upstream image needs
# to be fixed before packages can be installed
RUN set -x \
    && rpm --rebuilddb \
    ; yes | mv /var/lib/rpmrebuilddb.*/* /var/lib/rpm \
    && rm -rf /var/lib/rpmrebuilddb*

# Install cbdep
RUN curl https://packages.couchbase.com/cbdep/0.9.18/cbdep-0.9.18-linux -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

# Install miniconda3
# One of the benefits is: repo tool requires python 3.5+; the OS comes with python2.  miniconda3 is a flexible way
# of installing python on a system
RUN cbdep install -d /home/couchbase miniconda3-py39 4.9.2 && \
    chown -R couchbase:couchbase /home/couchbase/miniconda3-4.9.2


ENV AGENT_VERSION=4.3
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.rpm.sh | bash
RUN yum install -y git-lfs
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar
ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

COPY build/swarm*.properties /
COPY build/couchbuilder_start.sh /usr/sbin/
