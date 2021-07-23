# Docker container for Centos 7.3

FROM centos:7.3.1611
LABEL maintainer="build-team@couchbase.com"

USER root
RUN yum clean all && yum swap -y fakesystemd systemd

RUN yum install --setopt=keepcache=0 -y \
		deltarpm \
		git \
		sudo \
		which \
    yum-plugin-ovl

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

# Oracle JDK (for Jenkins and Analytics).
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl --fail -L --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz -o jdk.tgz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/jdk.tgz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy
ENV JAVA_HOME=/usr/local/java

# Swarm client jar - only needed until CBD-4101 is resolved
RUN curl --fail \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.25/swarm-client-3.25.jar \
    -o /usr/local/lib/swarm-client.jar

# * repo
RUN curl --fail https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# FPM packaging tool
# Need to lock some versions because newer ones require higher versions of ruby
RUN yum install -y ruby-devel gcc make rpm-build rubygems

RUN gem install ffi:1.12.2 && \
    gem install fpm:1.11.0

# GCC (from couchbasebuild/centos-7-gcc)
COPY build/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# Install Couchbase Lite Core toolchain requirements
RUN yum install -y --setopt=keepcache=0 tar openssl-devel make redhat-lsb-core wget unzip zip

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl --fail -L https://www.samba.org/ftp/ccache/ccache-3.3.4.tar.xz -o /tmp/deploy/ccache.tar.xz && \
    cd /tmp/deploy && tar -xf ccache.tar.xz && \
    cd ccache-3.3.4 && ./configure --prefix=/usr/local && make -j8 && make install && \
    rm -fr /tmp/deploy

# * CMake (from cmake.org)
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v3.20/cmake-3.20.1-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# fr_FR locale for LiteCore testing
RUN sudo localedef -v -c -i fr_FR -f UTF-8 fr_FR || true

# Add "shasum" command (use by cbl-java build, at least)
RUN yum install -y --setopt=keepcache=0 perl-Digest-SHA

# Add cbdep tool (used by cbl-java build, at least)
RUN curl --fail http://downloads.build.couchbase.com/cbdep/cbdep.linux -o /usr/local/bin/cbdep && chmod 755 /usr/local/bin/cbdep

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Entrypoint script and swarm properties - keep this towards end of Dockerfile
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
