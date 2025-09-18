FROM couchbasebuild/dfs:20250811
LABEL maintainer="build-team@couchbase.com"

ARG TARGETARCH
USER root

# Installer chroots - these are simple images that rarely change, so
# just pull :latest
COPY --from=couchbasebuild/deb-packager:latest / /opt/deb-chroot
COPY --from=couchbasebuild/rpm-packager:latest / /opt/rpm-chroot

# Since the couchbasebuild/xxx-packager images were built directly from
# a Dockerfile, they don't have any /dev/ stuff since Docker generally
# magicks those into existence when a container is started. They can't
# explicitly create them, either, since they already exist during
# "docker build". So, since we're copying them into a non-/ directory
# here, we need to create any such files ourselves. Experimentally, it
# seems like only /dev/null is really important.
RUN mknod -m 666 /opt/deb-chroot/dev/null c 1 3
RUN mknod -m 666 /opt/rpm-chroot/dev/null c 1 3

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
    && make -j${PARALLELISM} \
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

# xmllint (libxml2)
ARG LIBXML2_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -LsSf https://download.gnome.org/sources/libxml2/2.14/libxml2-${LIBXML2_VERSION}.tar.xz | tar -xJ --strip-components=1 -C ${tmpsrc} \
    && cd ${tmpsrc} \
    && ./configure --prefix=/usr --disable-static --without-python \
    && make -j${PARALLELISM} \
    && make install-strip

# vim
ARG VIM_VERSION
RUN --mount=type=tmpfs,target=${tmpsrc} set -x \
    && curl -LsSf https://github.com/vim/vim/archive/refs/tags/v${VIM_VERSION}.tar.gz | tar -xz --strip-components=1 -C ${tmpsrc} \
    && cd ${tmpsrc} \
    && ./configure --prefix=/usr --with-features=huge \
            --enable-gui=no --without-x    \
            --with-tlib=ncursesw  \
    && make -j${PARALLELISM} \
    && make install \
    && ln -s /usr/bin/vim vi

# Our tools
ARG PATCH_VIA_GERRIT_VERSION
RUN curl -Lf https://packages.couchbase.com/patch_via_gerrit/${PATCH_VIA_GERRIT_VERSION}/patch_via_gerrit-${PATCH_VIA_GERRIT_VERSION}-linux-$(uname -m) -o /usr/local/bin/patch_via_gerrit && \
    chmod a+x /usr/local/bin/patch_via_gerrit

# cbdep is a rolling PyPI release now, so we always just want "latest".
# We use `uv` to install it, so install that first. Also use `uv` to put
# `python` on the PATH. All this is done as the `couchbase` user.
USER couchbase
ENV PATH=/home/couchbase/.local/bin:$PATH
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN set -x \
    && uv python install --default --preview-features python-install-default ${PYTHON_VERSION} \
    && uv tool install cbdep

# Need to create some directories so that the swarm stackfile can mount
# on top of them without messing up permissions / ownership.
RUN mkdir -p /home/couchbase/jenkins/workspace /home/couchbase/.cbdepscache /home/couchbase/.cbdepcache/ /home/couchbase/.ccache

USER root

# Remember this path for Jenkins agents (see entrypoint script)
RUN echo "/home/couchbase/.local/bin" >> /etc/path

# Use cbdep to install JVM for Jenkins
ARG JDK_VERSION
RUN set -x \
    && cbdep install -d /usr/local openjdk ${JDK_VERSION} \
    && rm -rf /root/.cbdepcache \
    && ln -s /usr/local/openjdk-${JDK_VERSION}/bin/java /usr/local/bin/java

RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}

USER couchbase

COPY hostname /home/couchbase/.local/bin

ADD --chmod=0755 https://cb-entry.s3.us-west-2.amazonaws.com/universal-entrypoint.sh /universal_entrypoint.sh
ENTRYPOINT ["/universal_entrypoint.sh"]
CMD []
