# Docker container for Ubuntu 16.04

FROM ubuntu:16.04
MAINTAINER build-team@couchbase.com

USER root

# Install SSH server
RUN apt-get update && \
    apt-get install -y openssh-server sudo && \
    apt-get clean && \
    mkdir /var/run/sshd # update

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN useradd couchbase -G sudo -m -s /bin/bash && \
    mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Install Couchbase build dependencies
RUN apt-get update && \
    apt-get install -y \
    binutils \
    ccache \
    curl \
    debhelper \
    dh-systemd \
    devscripts \
    ed \
    g++ \
    git-core \
    libc-bin \
    libc6-i386 \
    libssl-dev \
    man \
    ncurses-dev \
    python-dev \
    python-pip \
    rake \
    ruby \
    tar  && \
    apt-get clean
RUN echo 'PATH="/usr/lib/ccache:$PATH"' >> /home/couchbase/.profile
RUN curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo && \
    cd /tmp && rm -rf /tmp/deploy

# PyInstaller is required by sgcollect_info
RUN pip install -Iv PyInstaller==3.1

# golang (install a current default, specific version should be in Jenkins's job)
RUN mkdir -p /usr/local/go/1.11.2 && cd /usr/local/go/1.11.2 && \
    curl https://storage.googleapis.com/golang/go1.11.2.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
rm go.tar.gz

# JDK for Jenkins.
RUN apt-get install -y openjdk-8-jre-headless && \
    rm -f /var/cache/apt/archives/*.deb

# Update locale
RUN apt-get update && \
    apt-get install -y locales && \
    apt-get clean && \
    locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ADD .ssh /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]

