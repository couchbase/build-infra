# Docker container for Centos 6.6

# See https://github.com/ceejatec/naked-docker/ for details about the
# construction of the base image.

FROM centos:6.6
MAINTAINER build-team@couchbase.com

USER root
RUN yum install -y yum-plugin-ovl
RUN yum clean all && yum install -y --setopt=keepcache=0 openssh-server sudo

# Set up for SSH daemon
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config && \
    /etc/init.d/sshd start

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
                glibc.i686 \
                make \
                man \
                ncurses-devel \
                nss \
                openssh-clients openssl-devel \
                redhat-lsb-core \
                rpm-build \
                ruby rubygems rubygem-rake \
                tar \
                unzip \
                which

# JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.4%2B11/OpenJDK11U-jre_x64_linux_hotspot_11.0.4_11.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

# * Required for sgcollect_info
RUN yum install --setopt=keepcache=0 -y https://centos6.iuscommunity.org/ius-release.rpm && \
    yum install --setopt=keepcache=0 -y python27 && \
    curl -L https://bootstrap.pypa.io/get-pip.py | python2.7 && \
    pip install --upgrade pip -Iv PyInstaller==3.1

# * C++11 compliant compiler and related tools from CentOS's port of RHEL's
#    devtools (http://people.centos.org/tru/devtools-2/)
RUN curl -L http://people.centos.org/tru/devtools-2/devtools-2.repo > \
         /etc/yum.repos.d/devtools-2.repo && \
    yum install --setopt=keepcache=0 -y \
                devtoolset-2-gcc-c++ \
                devtoolset-2-binutils && \
    ln -s /opt/rh/devtoolset-2/root/usr/bin/as /usr/local/bin/as && \
    ln -s /opt/rh/devtoolset-2/root/usr/bin/gcc /usr/bin/gcc && \
    ln -s /opt/rh/devtoolset-2/root/usr/bin/cc /usr/bin/cc && \
    ln -s /opt/rh/devtoolset-2/root/usr/bin/g++ /usr/bin/g++ && \
    ln -s /opt/rh/devtoolset-2/root/usr/bin/c++ /usr/bin/c++

# * CMake (from cmake.org)
RUN mkdir /tmp/deploy && \
    curl -L https://cmake.org/files/v3.6/cmake-3.6.1-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl -L https://www.samba.org/ftp/ccache/ccache-3.1.9.tar.bz2 -o /tmp/deploy/ccache.tar.bz2 && \
    cd /tmp/deploy && tar -xjf ccache.tar.bz2 && \
    cd ccache-3.1.9 && ./configure --prefix=/usr/local && make -j8 && make install && \
    ln -s ccache /usr/local/bin/gcc && \
    ln -s ccache /usr/local/bin/g++ && \
    ln -s ccache /usr/local/bin/cc && \
    ln -s ccache /usr/local/bin/c++ && \
    rm -fr /tmp/deploy

# * golang
RUN mkdir -p /usr/local/go/1.4.1 && cd /usr/local/go/1.4.1 && \
    curl https://storage.googleapis.com/golang/go1.4.1.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.5.2 && cd /usr/local/go/1.5.2 && \
    curl https://storage.googleapis.com/golang/go1.5.2.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.5.3 && cd /usr/local/go/1.5.3 && \
    curl https://storage.googleapis.com/golang/go1.5.3.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.7.1 && cd /usr/local/go/1.7.1 && \
    curl https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz && \
    mkdir /usr/local/go/1.7.4 && cd /usr/local/go/1.7.4 && \
    curl https://storage.googleapis.com/golang/go1.7.4.linux-amd64.tar.gz -o go.tar.gz && \
    tar xzf go.tar.gz

# * repo
RUN curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# * git
RUN yum install -y --setopt=keepcache=0 devtoolset-2-git && \
    ln -s /opt/rh/devtoolset-2/root/usr/bin/git /usr/local/bin/git

# Install third-party build dependencies
RUN yum install -y --setopt=keepcache=0 m4 file

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ADD .ssh /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]

# Needed for sg
ADD .rpmmacros /home/couchbase/

RUN chown couchbase:couchbase /home/couchbase/.rpmmacros

