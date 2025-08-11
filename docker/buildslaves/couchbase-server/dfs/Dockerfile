# chroot for Debian installer - use debootstrap
FROM debian:12 AS debian-chroot-compile

ARG DEBIAN_CODENAME=bullseye \
    TARGETARCH
# Need binutils for 'strip'
RUN apt-get update && apt-get install -y --no-install-recommends debootstrap binutils
RUN mkdir -p /opt/deb-chroot
RUN set -x \
    && ulimit -n 1024 \
    && debootstrap --arch=${TARGETARCH} \
         --variant=minbase \
         --include dpkg-dev,debhelper,libtinfo5,fakeroot \
         ${DEBIAN_CODENAME} /opt/deb-chroot http://deb.debian.org/debian
RUN set -x \
    && rm -rf /opt/deb-chroot/var/lib/apt \
    && rm -rf /opt/deb-chroot/var/log/* \
    && rm -rf /opt/deb-chroot/var/cache/{apt,man} \
    && rm -rf /opt/deb-chroot/usr/share/{doc,info,man}
RUN cd /opt/deb-chroot/usr/lib \
    && find . -type f -print0 | xargs -0 -n 50 strip || true
RUN LC_ALL=C chroot /opt/deb-chroot /bin/bash -c \
    'groupadd -g 1000 couchbase && useradd -g couchbase -u 1000 couchbase'

# chroot for RPM installer - use rinse from Debian (weird, right?).
FROM debian:12 AS rpm-chroot-compile

ARG RPM_CODENAME=rocky-8 \
    TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends rinse \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/rpm-chroot
# 'rinse' doesn't seem to return a non-zero exit code if it fails, so we
# stick the extra `ls -l` command in there to ensure that the build fails if
# the chroot is not created correctly.
RUN set -x \
    && ulimit -n 1024 \
    && if [ "${TARGETARCH}" = "arm64" ]; then TARGETARCH=aarch64; fi \
    && rinse --arch=${TARGETARCH} --distribution=${RPM_CODENAME} --directory /opt/rpm-chroot \
    && ls -l /opt/rpm-chroot/bin/bash
RUN LC_ALL=C chroot /opt/rpm-chroot /bin/bash -c 'ulimit -n 1024 && yum install -y rpm-build && yum clean all'
RUN set -x \
    && rm -rf /opt/rpm-chroot/var/cache/dnf \
    && rm -rf /opt/rpm-chroot/usr/share/{doc,info,man} \
    && find /opt/rpm-chroot --name __pycache__ -print0 | xargs -0 rm -rf
RUN LC_ALL=C chroot /opt/rpm-chroot /bin/bash -c \
    'groupadd -g 1000 couchbase && useradd -g couchbase -u 1000 couchbase'

FROM couchbasebuild/dfs:20250809
LABEL maintainer="build-team@couchbase.com"

ARG TARGETARCH
USER root

# Installer chroots
COPY --from=debian-chroot-compile /opt/deb-chroot /opt/deb-chroot
COPY --from=rpm-chroot-compile /opt/rpm-chroot /opt/rpm-chroot

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN groupadd -g1000 couchbase && \
    useradd couchbase -g couchbase -u1000 -G wheel -m -s /bin/bash && \
    mkdir /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase && \
    echo 'couchbase:couchbase' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults:%wheel !requiretty' >> /etc/sudoers.d/wheel_group && \
    echo 'Defaults env_keep += "PATH"' >> /etc/sudoers.d/wheel_group && \
    sed -i 's/^Defaults\s\+secure_path.*/# &/' /etc/sudoers && \
    chmod 440 /etc/sudoers.d/wheel_group && \
    usermod -G wheel root

ARG PARALLELISM=8

# libxxhash (required for rsync)
ARG tmpsrc=/tmp/deploy
ARG LIBXXHASH_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -LsSf https://github.com/Cyan4973/xxHash/archive/refs/tags/v${LIBXXHASH_VERSION}.tar.gz | tar -xz --strip-components=1 -C ${tmpsrc} \
    && make -C ${tmpsrc} -j${PARALLELISM} prefix=/usr mandir=${tmpsrc}/man install

# rsync (required for profiledata)
ARG RSYNC_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x\
    && curl -LsSf https://download.samba.org/pub/rsync/src/rsync-${RSYNC_VERSION}.tar.gz | tar -xz --strip-components=1 -C ${tmpsrc} \
    && cd ${tmpsrc} \
    && ./configure --prefix=/usr --disable-md2man \
    && make -j${PARALLELISM} \
    && make install-strip

# CMake
ARG CMAKE_VERSION
RUN curl -Lf https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-$(uname -m).tar.gz | \
    tar -xz --strip-components=1 -C /usr cmake-${CMAKE_VERSION}-linux-$(uname -m)/{bin,share}

# Ccache
ARG CCACHE_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -Lf https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}.tar.xz | tar -xJ --strip-components=1 -C ${tmpsrc} \
    && cd ${tmpsrc} \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr .. \
    && make -j8 \
    && make install

# repo
RUN set -x \
    && curl -Lf https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && sed -i 's/env python$/env python3/' /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# jq and yq
ARG JQ_VERSION
ARG YQ_VERSION
RUN set -x \
    && curl -L --fail -o /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${TARGETARCH} \
    && chmod a+x /usr/local/bin/jq \
    && curl -L --fail -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} \
    && chmod a+x /usr/local/bin/yq

# Our tools
ARG PATCH_VIA_GERRIT_VERSION
RUN curl -Lf https://packages.couchbase.com/patch_via_gerrit/${PATCH_VIA_GERRIT_VERSION}/patch_via_gerrit-${PATCH_VIA_GERRIT_VERSION}-linux-$(uname -m) -o /usr/local/bin/patch_via_gerrit && \
    chmod a+x /usr/local/bin/patch_via_gerrit
# cbdep is a rolling PyPI release now, so we always just want "latest".
# We use `uv` to install it, so install that first. All this is done as the `couchbase` user.
USER couchbase
ENV PATH=/home/couchbase/.local/bin:$PATH
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN set -x \
    && uv python install 3.11 \
    && ln -s /home/couchbase/.local/bin/python3.11 /home/couchbase/.local/bin/python \
    && ln -s /home/couchbase/.local/bin/python3.11 /home/couchbase/.local/bin/python3
RUN uv tool install cbdep

# Need to create some directories so that the swarm stackfile can mount
# on top of them without messing up permissions / ownership.
RUN mkdir -p /home/couchbase/jenkins/workspace /home/couchbase/.cbdepscache /home/couchbase/.cbdepcache/ /home/couchbase/.ccache

USER root

# Remember this path for Jenkins agents (see entrypoint script)
RUN echo "/home/couchbase/.local/bin" >> /etc/path

# Use cbdep to install JVM for Jenkins
ARG JDK_VERSION
RUN cbdep install -d /usr/local openjdk ${JDK_VERSION} \
    && ln -s /usr/local/openjdk-${JDK_VERSION}/bin/java /usr/local/bin/java

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}

COPY hostname /home/couchbase/.local/bin

ADD --chmod=0755 https://cb-entry.s3.us-west-2.amazonaws.com/universal-entrypoint.sh /universal_entrypoint.sh
ENTRYPOINT ["/universal_entrypoint.sh"]
CMD []
