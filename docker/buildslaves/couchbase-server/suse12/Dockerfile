# Docker container for SuSE 12.0 SP2

# See https://github.com/ceejatec/naked-docker/ for details about the
# construction of the base image.

FROM suse/sles12sp2:latest
LABEL maintainer="build-team@couchbase.com"

USER root
ARG REGCODE
RUN zypper ref -s
RUN zypper install -y SUSEConnect
RUN SUSEConnect -r ${REGCODE} -e staff_qe@couchbase.com
RUN SUSEConnect -p sle-sdk/12.2/x86_64
RUN zypper ref -s
RUN zypper -n in vim
RUN zypper -n install openssh sudo && zypper clean

# Set up for SSH daemon
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config && \
    sed -ri 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config && \
    sed -ri 's/#PermitUserEnvironment no/PermitUserEnvironment yes/g' /etc/ssh/sshd_config && \
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

### Install Couchbase build dependencies ######################################
RUN zypper -n install \
                binutils \
                curl \
                ccache \
                ed \
                git \
                glib2-devel \
                libffi48-devel \
                libnuma-devel \
                libopenssl-devel \
                lsb-release \
                make \
                man \
                ncurses-devel \
                python-devel \
                python-xml \
                rpm-build \
                rsync \
                ruby rubygems rubygem-rake \
                sqlite3-devel \
                tar \
                unzip \
    && zypper clean

# GCC (from localonly/suse-12-gcc)
ARG GCC_VER
RUN mkdir -p /opt && ln -s gcc-${GCC_VER} /opt/gcc
COPY build/gcc-${GCC_VER} /opt/gcc-${GCC_VER}
COPY build/local /usr/local
RUN  (echo "/usr/local/lib64"; cat /etc/ld.so.conf) > /tmp/ld.so.conf && \
     mv /tmp/ld.so.conf /etc && ldconfig

# * CMake (from cmake.org)
ARG CMAKE_MAJOR
ARG CMAKE_MINOR
ARG CMAKE_PATCH
RUN mkdir /tmp/deploy && \
    curl https://cmake.org/files/v${CMAKE_MAJOR}.${CMAKE_MINOR}/cmake-${CMAKE_MAJOR}.${CMAKE_MINOR}.${CMAKE_PATCH}-linux-x86_64.sh -o /tmp/deploy/cmake.sh && \
    (echo y ; echo n) | sh /tmp/deploy/cmake.sh --prefix=/usr/local && \
    rm -fr /tmp/deploy

# Install autoconf and friends - necessary for building some third-party deps
# from source, not for Couchbase. (The "full" version of perl is also required
# for some third-party builds, so don't remove that after building libtool.)\
ARG AUTOCONF_VER
ARG AUTOMAKE_VER
ARG LIBTOOL_VER
RUN set -x \
    && zypper -n install perl \
    && mkdir /tmp/deploy \
    && curl -Lf http://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.bz2 -o /tmp/deploy/m4-1.4.17.tar.bz2 \
    && cd /tmp/deploy && tar -xjf m4-1.4.17.tar.bz2 \
    && cd m4-1.4.17 && ./configure --prefix=/usr/local && make -j8 && make install \
    && curl -Lf http://ftpmirror.gnu.org/autoconf/autoconf-${AUTOCONF_VER}.tar.gz -o /tmp/deploy/autoconf-${AUTOCONF_VER}.tar.gz \
    && cd /tmp/deploy && tar -xzf autoconf-${AUTOCONF_VER}.tar.gz \
    && cd autoconf-${AUTOCONF_VER} && ./configure --prefix=/usr/local && make -j8 && make install \
    && curl -Lf http://ftpmirror.gnu.org/automake/automake-${AUTOMAKE_VER}.tar.gz -o /tmp/deploy/automake-${AUTOMAKE_VER}.tar.gz \
    && cd /tmp/deploy && tar -xzf automake-${AUTOMAKE_VER}.tar.gz \
    && cd automake-${AUTOMAKE_VER} && ./configure --prefix=/usr/local && make && make install \
    && curl -Lf http://ftpmirror.gnu.org/libtool/libtool-${LIBTOOL_VER}.tar.gz -o /tmp/deploy/libtool-${LIBTOOL_VER}.tar.gz \
    && cd /tmp/deploy && tar -xzf libtool-${LIBTOOL_VER}.tar.gz \
    && cd libtool-${LIBTOOL_VER} && ./configure --prefix=/usr/local && make -j8 && make install \
    && cd /tmp && rm -rf /tmp/deploy && zypper clean

# * repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Install cbdep
RUN curl https://packages.couchbase.com/cbdep/0.9.18/cbdep-0.9.18-linux -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

# Install miniconda3
# latest repo requires python 3.6+.  Official suse repository only provides python 3.3 for suse12
RUN cbdep install -d /home/couchbase miniconda3-py39 4.9.2 && \
    chown -R couchbase:couchbase /home/couchbase/miniconda3-4.9.2

# Oracle JDK (for Jenkins and Analytics).
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm -o jdk.rpm && \
    rpm -Uvh jdk.rpm && \
    cd /tmp && rm -rf deploy
ENV JAVA_HOME=/usr/java/latest

# Set LANG
ENV LANG=en_US.UTF-8

# Swarm client
RUN set -x \
        && cd /tmp \
        && curl -LO https://cdn.azul.com/zulu/bin/zulu11.43.55-ca-jdk11.0.9.1-linux.x86_64.rpm \
        && rpm -i ./zulu11.43.55-ca-jdk11.0.9.1-linux.x86_64.rpm

# Enable disk-checking healthcheck
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Docker Swarm properties - keep this towards end of Dockerfile
COPY build/swarm*.properties /

# Needs to be in .bashrc for some reason
RUN echo "export LANG=en_US.UTF-8" >> /home/couchbase/.bashrc

# Add jnlp agent for ECS/swarm invocation
ARG JNLP_AGENT_VER
RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JNLP_AGENT_VER}/remoting-${JNLP_AGENT_VER}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir /home/couchbase/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase /home/couchbase/.jenkins ${AGENT_WORKDIR}

# Install asciidoctor
ARG ASCIIDOCTOR_VER
RUN set -x \
    && gem install asciidoctor -v ${ASCIIDOCTOR_VER} \
    && ln -s /usr/bin/asciidoctor.ruby2.1 /usr/local/bin/asciidoctor

# Expose SSH daemon and run our builder startup script
EXPOSE 22
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
