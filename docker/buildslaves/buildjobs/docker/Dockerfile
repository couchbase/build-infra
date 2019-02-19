# Docker container for a Jenkins slave that can run Docker commands

FROM ubuntu:16.04
MAINTAINER build-team@couchbase.com

USER root

# Install SSH server and sudo, as well as git and a JRE for Jenkins
# and python 2.7 for repo
RUN apt-get update && \
    apt-get install -y openssh-server sudo apt-transport-https \
        ca-certificates curl git openjdk-8-jre-headless python2.7 && \
    apt-get clean && \
    mkdir /var/run/sshd && \
    ln -s /usr/bin/python2.7 /usr/local/bin/python

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Python3 updates and s3cmd
RUN apt-get update && \
    apt-get install -y python3-pip && \
    pip3 install s3cmd && \
    apt-get clean

# Add Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo apt-key add - && \
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" \
        >> /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y docker-ce && \
    apt-get clean

# Create couchbase user with password-less sudo privs and
# put in docker group
RUN useradd couchbase -G sudo,docker -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ADD .ssh /home/couchbase/.ssh
COPY couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]
