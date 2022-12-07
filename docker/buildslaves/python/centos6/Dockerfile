# Docker container for Centos 6.10

FROM centos:6.10
LABEL maintainer="build-team@couchbase.com"

USER root
COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

RUN yum install --setopt=keepcache=0 -y sudo curl \
        xz binutils glibc-devel \
        zlib-devel bzip2-devel \
        openssl-devel ncurses-devel sqlite-devel \
        readline-devel tk-devel gdbm-devel db4-devel \
        libpcap-devel xz-devel expat-devel curl-devel \
        rsync openssh-clients && \
    yum clean packages

# Historic gcc 7.3.0
COPY --from=couchbasebuild/centos-6-gcc:7.3.0 /usr/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN set -x && \
      groupadd -g1000 couchbase && \
      useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
      echo 'couchbase:couchbase' | chpasswd && \
      echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
      echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
      chmod 440 /etc/sudoers.d/wheel_group

# Python 3.9.6 (using miniforge)
ARG MINIFORGE_VER=4.10.3-5
RUN set -x && \
      curl -Lo /tmp/miniforge.sh \
        https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VER}/Miniforge3-${MINIFORGE_VER}-Linux-x86_64.sh && \
      sh /tmp/miniforge.sh -b -f -p /usr/local/miniforge && \
      rm /tmp/miniforge.sh
RUN for exe in python python3 pip pip3; do ln -s /usr/local/miniforge/bin/${exe} /usr/local/bin/${exe}; done

# Jenkins Swarm jar
RUN curl \
    https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.17/swarm-client-3.17.jar \
    -o /usr/local/lib/swarm-client.jar

# tini, to avoid zombie issues when running with Swarm jar
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# * git - needs to exist as /usr/bin/git for Git SCM Jenkins plugin
RUN set -x && \
      mkdir /tmp/deploy && \
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

# JRE for Jenkins.
RUN set -x \
    && ARCH=$(uname -m | sed -e 's/86_//') \
    && mkdir /tmp/deploy \
    && cd /tmp/deploy \
    && curl -Lf https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.5%2B8/OpenJDK17U-jre_${ARCH}_linux_hotspot_17.0.5_8.tar.gz -o openjre.tar.gz \
    && cd /usr/local \
    && tar xvzf /tmp/deploy/openjre.tar.gz \
    && ln -s jdk* java \
    && for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done \
    && rm -rf /tmp/deploy

# * ccache (from source)
RUN set -x && \
      mkdir /tmp/deploy && \
      curl -L https://www.samba.org/ftp/ccache/ccache-3.1.9.tar.bz2 -o /tmp/deploy/ccache.tar.bz2 && \
      cd /tmp/deploy && tar -xjf ccache.tar.bz2 && \
      cd ccache-3.1.9 && ./configure --prefix=/usr/local && make -j8 && make install && \
      rm -fr /tmp/deploy

# * repo
RUN curl https://raw.githubusercontent.com/couchbasedeps/git-repo/repo-1-couchbase/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]
