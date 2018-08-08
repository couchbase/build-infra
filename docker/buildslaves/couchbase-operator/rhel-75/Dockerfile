# Docker container for RHEL 7.5

# See https://github.com/ceejatec/naked-docker/ for details about the
# construction of the base image.

FROM registry.access.redhat.com/rhel7.5
MAINTAINER Couchbase Build Team <build-team@couchbase.com>

USER root

# Install Docker
RUN REPOLIST=rhel-7-server-rpms,rhel-7-server-optional-rpms,rhel-7-server-extras-rpms && \
    yum -y update-minimal --disablerepo "*" --enablerepo rhel-7-server-rpms \
        --setopt=tsflags=nodocs --security --sec-severity=Important --sec-severity=Critical && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs \
        docker-1.13.1 && \
    yum clean all

RUN yum clean all && yum install --setopt=keepcache=0 -y \
                deltarpm \
                git \
                openssh-server \
                sudo \
                which

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# Go 1.10.1
RUN mkdir -p /usr/local/go/1.10.1 && cd /usr/local/go/1.10.1 && \
    curl https://storage.googleapis.com/golang/go1.10.1.linux-amd64.tar.gz -o go.tar.gz && \
    tar xf go.tar.gz && \
    rm go.tar.gz && \
    ln -s /usr/local/go/1.10.1/go/bin/go /usr/local/bin

# Glide
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L https://github.com/Masterminds/glide/releases/download/v0.13.1/glide-v0.13.1-linux-amd64.tar.gz -o glide.tar.gz && \
    tar xf glide.tar.gz && \
    mv -i linux-amd64/glide /usr/local/bin && \
    cd /tmp && \
    rm -rf deploy

# Set up for SSH daemon
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config && \
    sed -ri 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ADD .ssh /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]
