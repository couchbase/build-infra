# Docker container for Centos7

FROM centos:centos7.4.1708
LABEL maintainer="build-team@couchbase.com"

USER root
# Use vault for package installation - CentOS 7 is now EOL, so the original
# mirrors are no longer available
RUN sed -i -e '/^mirrorlist/d;/^#baseurl=/{s,^#,,;s,/mirror,/vault,;}' /etc/yum.repos.d/CentOS*.repo
RUN yum clean all && \
    yum install --setopt=keepcache=0 -y sudo deltarpm

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    chmod 440 /etc/sudoers.d/wheel_group

# clean up nsswitch
RUN sed -ri 's/^hosts.*/hosts:      files dns/' /etc/nsswitch.conf

### Install build signing dependencies ######################################
RUN yum install --setopt=keepcache=0 -y \
                git rpm-sign createrepo expect

# Install uv and cbdep to /usr/local/bin
# And add /usr/local/bin/ to PATH
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh
RUN curl -Lf https://packages.couchbase.com/cbdep/cbdep-linux-$(uname -m) -o /usr/local/bin/cbdep \
    && chmod a+x /usr/local/bin/cbdep
RUN echo -n ":/usr/local/bin" >> /etc/path

# Use cbdep to install jdk for Jenkins
ARG JDK_VERSION=21.0.6+7
RUN cbdep install -d /usr/local openjdk ${JDK_VERSION} \
    && ln -s /usr/local/openjdk-${JDK_VERSION}/bin/java /usr/local/bin/java

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Ensure /opt/cbdeps is writable
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# Enable disk/memory healthchecks
COPY build/healthcheck.sh /usr/sbin/healthcheck.sh
HEALTHCHECK --interval=30s --retries=3 --timeout=90s --start-period=5s CMD /usr/sbin/healthcheck.sh

# Run our builder startup script
COPY build/couchbuilder_start.sh /usr/sbin/
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD [ "swarm" ]

# Ensure appropriate directories exist and are owned by 'couchbase'
USER couchbase
RUN mkdir /home/couchbase/.ssh

# Keep this stuff at the end, because the ARG declaration breaks Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
