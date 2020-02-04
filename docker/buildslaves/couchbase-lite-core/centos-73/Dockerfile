# Docker container for Centos 7.3

FROM centos:7.3.1611
MAINTAINER build-team@couchbase.com

USER root
RUN yum clean all && yum swap -y fakesystemd systemd

RUN yum install --setopt=keepcache=0 -y \
		deltarpm \
		git \
		openssh-server \
		sudo \
		which \
    yum-plugin-ovl

# Set up for SSH daemon
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri '/UsePAM yes/a UsePAM no' /etc/ssh/sshd_config && \
    sed -ri '0,/HostKey/s//Protocol 2\n&/' /etc/ssh/sshd_config  && \
    sed -ri 's/^HostKey/#HostKey/g' /etc/ssh/sshd_config && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# Oracle JDK (for Jenkins and Analytics).
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz -o jdk.tgz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/jdk.tgz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy
ENV JAVA_HOME=/usr/local/java

# * repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Expose SSH daemon and run our builder startup script
EXPOSE 22
RUN mkdir /home/couchbase/.ssh && chown couchbase:couchbase /home/couchbase/.ssh
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "default" ]

# FPM packaging tool.  
RUN yum install -y ruby-devel gcc make rpm-build rubygems && \
    gem install fpm

# GCC (from couchbasebuild/centos-7-gcc)
COPY build/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# Install Couchbase Lite Core toolchain requirements
RUN yum install -y --setopt=keepcache=0 tar openssl-devel make redhat-lsb-core wget unzip zip

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl -L https://www.samba.org/ftp/ccache/ccache-3.3.4.tar.xz -o /tmp/deploy/ccache.tar.xz && \
    cd /tmp/deploy && tar -xf ccache.tar.xz && \
    cd ccache-3.3.4 && ./configure --prefix=/usr/local && make -j8 && make install && \
    rm -fr /tmp/deploy

# * CMake (from cmake.org)
RUN mkdir /tmp/deploy && \
    curl -L https://cmake.org/files/v3.13/cmake-3.13.0-Linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm /usr/local/bin/cmake-gui && \
    rm -rf /tmp/deploy

# fr_FR locale for LiteCore testing
RUN sudo localedef -v -c -i fr_FR -f UTF-8 fr_FR || true

# Add "shasum" command (use by cbl-java build, at least)
RUN yum install -y --setopt=keepcache=0 perl-Digest-SHA

# Add cbdep tool (used by cbl-java build, at least)
RUN curl http://nas-n.mgt.couchbase.com/builds/downloads/cbdep/cbdep.linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep
