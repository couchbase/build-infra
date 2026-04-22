FROM couchbasebuild/zzz-lightweight:20260212
LABEL maintainer=build-team@couchbase.com

RUN apt-get update && apt-get install -y \
    python3 \
    libxml2-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /var/run/sshd

# Install repo command
RUN curl -f https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

# Install cbdep
RUN curl -Lf https://packages.couchbase.com/cbdep/cbdep-linux-$(uname -m) -o /usr/local/bin/cbdep && \
    chmod a+x /usr/local/bin/cbdep

USER root

# Use cbdep to install cmake
ARG CMAKE_VERSION
RUN cbdep install -d /usr/local cmake ${CMAKE_VERSION} \
    && ln -s /usr/local/cmake-${CMAKE_VERSION}/bin/cmake /usr/local/bin/cmake

COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /
COPY build/buildx.sh /usr/sbin/couchhook.d/

USER couchbase
RUN mkdir -p /home/couchbase/jenkins/workspace /home/couchbase/.cbdepscache /home/couchbase/.cbdepcache/ /home/couchbase/.ccache
