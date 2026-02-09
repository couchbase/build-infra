# Docker container for a Jenkins slave that can run Docker commands

FROM ubuntu:20.04
LABEL maintained="build-team@couchbase.com"

USER root

# Ensure apt-get doesn't prompt us for stuff (use ARG so this value
# doesn't persist into the image)
ARG DEBIAN_FRONTEND=noninteractive

# Install SSH server and sudo, as well as git
RUN apt-get update && \
    apt-get install -y openssh-server sudo apt-transport-https \
        ca-certificates curl git unzip && \
    apt-get clean && \
    mkdir /var/run/sshd

# JDK for Jenkins
RUN mkdir /tmp/deploy && \
curl --fail -L "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jre_x64_linux_hotspot_21.0.5_11.tar.gz" -o /tmp/deploy/openjre.tar.gz && \
cd /usr/local && \
tar xvzf /tmp/deploy/openjre.tar.gz && \
ln -s jdk* java && \
for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
rm -rf /tmp/deploy
ENV JAVA_HOME=/usr/local/java

# Repo
RUN curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Python3 updates and s3cmd
RUN set -x \
      && apt-get update \
      && apt-get install -y python3-pip \
      && apt-get clean

# AWS CLI
RUN set -x \
      && mkdir /tmp/deploy \
      && cd /tmp/deploy \
      && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
      && unzip awscliv2.zip \
      && ./aws/install \
      && cd /tmp \
      && rm -rf deploy
ENV AWS_SHARED_CREDENTIALS_FILE=/home/couchbase/.ssh/aws-credentials

# Install Docker command-line tools
RUN groupadd -g 999 docker
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl https://download.docker.com/linux/static/stable/x86_64/docker-20.10.7.tgz -o docker.tgz && \
    tar xf docker.tgz && \
    cp -a docker/docker /usr/local/bin && \
    cd /tmp && \
    rm -rf deploy

# Other useful tools - jq is used by at least the rebase-dockerhub job
RUN set -x \
      && apt-get update \
      && apt-get install -y jq \
      && apt-get clean

# Create couchbase user with password-less sudo privs and
# put in docker group
RUN useradd couchbase -G sudo,docker -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ADD .ssh /home/couchbase/.ssh

# Add aws config file
COPY aws.config /home/couchbase/.aws/config
RUN chown -R couchbase:couchbase /home/couchbase/.aws /home/couchbase/.ssh

# Hook to set up docker config
COPY docker-hook.sh /usr/sbin/couchhook.d/docker-hook.sh
COPY build/couchbuilder_start.sh /usr/sbin

ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]
