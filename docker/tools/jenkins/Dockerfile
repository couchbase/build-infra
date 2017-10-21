FROM jenkins/jenkins:2.73.2
MAINTAINER Couchbase Build Team <build-team@couchbase.com>

# Just need to ensure the static 'docker' binary is available on master,
# so we can use it for swarm operation jobs
USER root
RUN groupadd -g 999 docker && adduser jenkins docker
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl https://download.docker.com/linux/static/stable/x86_64/docker-17.09.0-ce.tgz -o docker.tgz && \
    tar xf docker.tgz && \
    cp -a docker/docker /usr/local/bin && \
    cd /tmp && \
    rm -rf deploy
USER jenkins
