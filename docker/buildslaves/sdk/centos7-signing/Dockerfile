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

# JDK for Jenkins.
RUN mkdir /tmp/deploy && \
    cd /tmp/deploy && \
    curl -L https://github.com/AdoptOpenJDK/openjdk17-binaries/releases/download/jdk-2021-05-07-13-31/OpenJDK-jre_x64_linux_hotspot_2021-05-06-23-30.tar.gz -o openjre.tar.gz && \
    cd /usr/local && \
    tar xvzf /tmp/deploy/openjre.tar.gz && \
    ln -s jdk* java && \
    for file in /usr/local/java/bin/*; do ln -s $file /usr/local/bin; done && \
    rm -rf /tmp/deploy

# Repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Ensure /opt/cbdeps is writable
RUN mkdir /opt/cbdeps && \
    chown couchbase:couchbase /opt/cbdeps && \
    chmod 755 /opt/cbdeps

# Install "cbdep" for `couchbase` user
# CBD-6552, cbdep symbolic link in /home/couchbase/.local/bin often goes missing.
# Ensure cbdep is on PATH by add "/home/couchbase/.local/share/uv/tools/cbdep/bin" to PATH.
RUN echo -n ":/home/couchbase/.local/bin:/home/couchbase/.local/share/uv/tools/cbdep/bin" >> /etc/path
ENV PATH="/home/couchbase/.local/bin:/home/couchbase/.local/share/uv/tools/cbdep/bin:${PATH}"
USER couchbase
RUN set -x \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && uv tool install cbdep
USER root

# Add hook to update cbdep on each container start
COPY build/update-cbdep.sh /usr/sbin/couchhook.d/update-cbdep.sh

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
