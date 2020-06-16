# This Dockerfile exists only to update the Jenkins Swarm jar in the
# existing Docker image. We don't want to rebuild some of the older
# historic images and risk raising unexpected issues when rebuilding
# older releases. The file Dockerfile.historic is the Dockerfile that
# the image was originally build from.

FROM couchbasebuild/server-centos6-build:20181218

RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.17/swarm-client-3.17.jar \
    -o /usr/local/lib/swarm-client.jar

RUN yum install -y rsync && yum clean packages

RUN set -x \
  && mkdir /tmp/deploy \
  && cd /tmp/deploy \
  && curl -L https://repo.anaconda.com/miniconda/Miniconda2-4.7.12.1-Linux-x86_64.sh -o miniconda2.sh \
  && chmod 755 miniconda2.sh \
  && ./miniconda2.sh -b -f -p /home/couchbase/miniconda2

RUN rm -rf /home/couchbase/.ssh

COPY build/couchbuilder_start.sh /usr/sbin/
