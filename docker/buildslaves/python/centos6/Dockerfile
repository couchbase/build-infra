# Docker container for Centos 6.9

FROM centos:6.9
MAINTAINER build-team@couchbase.com

USER root
RUN yum install --setopt=keepcache=0 -y sudo curl \
        gcc-c++ xz binutils \
        zlib-devel bzip2-devel \
        openssl-devel ncurses-devel sqlite-devel \
        readline-devel tk-devel gdbm-devel db4-devel \
        libpcap-devel xz-devel expat-devel curl-devel && \
    yum clean packages

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# Python 3.6.6
# Note we force pip==18.1, as there is a bug in pip 19.0.1 which prevents
# PyInstaller and others from installing:
# https://github.com/pypa/pip/issues/6163
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -LO http://python.org/ftp/python/3.6.6/Python-3.6.6.tar.xz && \
    tar xf Python-3.6.6.tar.xz && \
    cd Python-3.6.6 && \
    ./configure --prefix=/usr/local \
        --enable-shared LDFLAGS="-Wl,-rpath /usr/local/lib" && \
    make && make altinstall && \
    strip /usr/local/lib/libpython3.6m.so.1.0 && \
    ln -s /usr/local/bin/python3.6 /usr/local/bin/python3 && \
    /usr/local/bin/python3.6 -m pip install -U pip==18.1 && \
    cd /tmp && \
    rm -rf deploy

# Jenkins Swarm jar
RUN yum install --setopt=keepcache=0 -y java-1.8.0-openjdk-headless && \
    yum clean packages
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.13/swarm-client-3.13.jar \
    -o /usr/local/lib/swarm-client.jar

# tini, to avoid zombie issues when running with Swarm jar
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# * git - needs to exist as /usr/bin/git for Git SCM Jenkins plugin
RUN mkdir /tmp/deploy && \
    yum install --setopt=keepcache=0 -y gettext && \
    curl -L https://www.kernel.org/pub/software/scm/git/git-2.9.5.tar.xz -o /tmp/deploy/git.tar.xz && \
    cd /tmp/deploy && \
    tar xf git.tar.xz && \
    cd git-2.9.5 && \
    ./configure --prefix=/usr/local && \
    make -j8 NO_PERL=YesPlease && \
    make NO_PERL=YesPlease install && \
    cd /tmp && \
    rm -rf deploy && \
    yum remove -y gettext cvs perl && \
    cd /usr/local/libexec/git-core && \
    find . -samefile git -name 'git-*' -exec ln -sf git {} \; && \
    (strip * || true) && \
    ln -s /usr/local/bin/git /usr/bin/git

# * ccache (from source)
RUN mkdir /tmp/deploy && \
    curl -L https://www.samba.org/ftp/ccache/ccache-3.1.9.tar.bz2 -o /tmp/deploy/ccache.tar.bz2 && \
    cd /tmp/deploy && tar -xjf ccache.tar.bz2 && \
    cd ccache-3.1.9 && ./configure --prefix=/usr/local && make -j8 && make install && \
    rm -fr /tmp/deploy

# * repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Python libs
RUN pip3.6 install pyinstaller

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
