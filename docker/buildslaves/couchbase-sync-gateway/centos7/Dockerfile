# Docker container for Centos 7.0

FROM centos:7.0.1406
LABEL maintainer="build-team@couchbase.com"

USER root
RUN yum clean all && yum swap -y fakesystemd systemd
RUN yum install --setopt=keepcache=0 -y yum-plugin-ovl && yum clean all
RUN yum install --setopt=keepcache=0 -y sudo deltarpm

# clean up nsswitch
RUN sed -ri 's/^hosts.*/hosts:      files dns/' /etc/nsswitch.conf

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

### Install Couchbase build dependencies ######################################
# * Packages from the base CentOS repository
RUN yum install --setopt=keepcache=0 -y \
                curl \
                ed \
                gcc \
                gcc-c++ \
                git \
                glibc.i686 \
                make \
                man \
                ncurses-devel \
                nss \
                numactl-devel \
                openssh-clients openssl-devel \
                python-devel \
                redhat-lsb-core \
                rpm-build \
                rsync \
                ruby rubygems rubygem-rake \
                tar \
                unzip \
                which && \
    ln -s /usr/bin/python2.7 /usr/bin/python2.6

# * Required for sgcollect_info
RUN mkdir /tmp/deploy && \
    curl --fail --insecure https://bootstrap.pypa.io/pip/2.7/get-pip.py -o /tmp/deploy/get-pip.py && \
    python /tmp/deploy/get-pip.py && \
    rm -rf /tmp/deploy
RUN pip install --upgrade pip -Iv PyInstaller==3.1

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl --fail -L https://www.samba.org/ftp/ccache/ccache-3.1.9.tar.bz2 -o /tmp/deploy/ccache.tar.bz2 && \
    cd /tmp/deploy && tar -xjf ccache.tar.bz2 && \
    cd ccache-3.1.9 && ./configure --prefix=/usr/local && make -j8 && make install && \
    ln -s ccache /usr/local/bin/gcc && \
    ln -s ccache /usr/local/bin/g++ && \
    ln -s ccache /usr/local/bin/cc && \
    ln -s ccache /usr/local/bin/c++ && \
    rm -fr /tmp/deploy

# * golang
RUN mkdir -p /usr/local/go/1.4.1 && cd /usr/local/go/1.4.1 && \
    curl --fail https://storage.googleapis.com/golang/go1.4.1.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.5.2 && cd /usr/local/go/1.5.2 && \
    curl --fail https://storage.googleapis.com/golang/go1.5.2.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.5.3 && cd /usr/local/go/1.5.3 && \
    curl --fail https://storage.googleapis.com/golang/go1.5.3.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.7.1 && cd /usr/local/go/1.7.1 && \
    curl --fail https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.7.4 && cd /usr/local/go/1.7.4 && \
    curl --fail https://storage.googleapis.com/golang/go1.7.4.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.8.5 && cd /usr/local/go/1.8.5 && \
    curl --fail https://storage.googleapis.com/golang/go1.8.5.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.9 && cd /usr/local/go/1.9 && \
    curl --fail https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    rm go.tar.gz

# * repo
RUN curl --fail https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Install third-party build dependencies
RUN yum install -y --setopt=keepcache=0 m4 file

# JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl --fail -L https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11/OpenJDK11U-jre_x64_linux_hotspot_11.0.4_11.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

# Swarm client jar - only needed until CBD-4101 is resolved
RUN curl --fail \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.25/swarm-client-3.25.jar \
    -o /usr/local/lib/swarm-client.jar

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Needed for sg
ADD .rpmmacros /home/couchbase/

RUN chown couchbase:couchbase /home/couchbase/.rpmmacros
