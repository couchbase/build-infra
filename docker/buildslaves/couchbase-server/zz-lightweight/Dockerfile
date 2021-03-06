# Docker container for zz-lightweight

FROM ubuntu:20.04
LABEL maintainer="build-team@couchbase.com"

USER root

# Install tzdata, telling it to skip user interaction
RUN set -x \
    && apt-get update \
    && TZ=America/Los_Angeles DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata \
    && apt-get clean

# Update locale
RUN set -x \
    && apt-get update \
    && apt-get install -y locales \
    && apt-get clean \
    && locale-gen en_US.UTF-8

# Install required apt packages, i.e. build-essential, sudo, curl, common, SSHD, apt-utils
RUN apt-get update \
    && apt-get install -y \
       apt-utils \
       build-essential \
       curl \
       openssh-server \
       software-properties-common \
       sudo \
       unzip -y \
       zip -y \
    && apt-get clean \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && mkdir /var/run/sshd

# Create couchbase user with password-less sudo privs, and give
# ownership of /opt/couchbase
RUN set -x \
    && useradd couchbase -G sudo -m -s /bin/bash \
    && mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase \
    && echo 'couchbase:couchbase' | chpasswd \
    && sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# JDK and Jenkins Swarm jar
RUN set -x \
    && apt-get update \
    && apt-get install -y openjdk-11-jre-headless \
    && apt-get clean

# s3cmd for upload script
# this can be removed once all jobs have been switched from s3cmd to aws cli (CBD-3970)
RUN apt-get update \
    && apt-get install -y s3cmd \
    && apt-get clean

# Install python3-dev and python3-apt
RUN set -x \
    && apt-get update \
    && apt-get install -y \
       python3-dev \
       python3-apt \
    && apt-get clean \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 100 \
    && cp /usr/lib/python3/dist-packages/apt_pkg.cpython-38-x86_64-linux-gnu.so /usr/lib/python3/dist-packages/apt_pkg.so

# Install python3-venv for blackduck
RUN set -x \
    && apt-get update \
    && apt-get install python3-venv -y \
    && apt-get clean

# pip3 and python modules required by
# i.e. jira, blackduck
RUN set -x \
    && curl https://bootstrap.pypa.io/get-pip.py | python3 \
    && rm -f /usr/local/bin/pip /usr/local/bin/easy_install \
    && pip3 install requests lxml oauthlib pycrypto boto3 pbr wheel filemagic --upgrade\
    && pip3 install jira

# Set AWS credentials file environmental variable (probably used by jira, should use ~/.aws instead)
ENV AWS_SHARED_CREDENTIALS_FILE=/home/couchbase/.ssh/aws-credentials

# Utilities that are handy for zz-lightweight jobs and occasional interactive use
RUN apt-get update \
    && apt-get install -y jq vim \
    && apt-get clean

# Install latest git
RUN set -x \
    && add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y git \
    && apt clean

# Install repo
RUN set -x \
    && curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# Install rsync
RUN set -x \
    && apt-get update \
    && apt-get install -y rsync \
    && apt-get clean

#install rvm so that we can use it to upgrade ruby when necessary
RUN set -x \
    && groupadd rvm \
    && sudo apt-add-repository -y ppa:rael-gc/rvm \
    && sudo apt-get update \
    && sudo apt-get install -y rvm \
    && apt clean

# Install Deno for running javascript
RUN set -x \
    && cd /usr/local/bin \
    && curl --fail -Lo deno.zip https://github.com/denoland/deno/releases/download/v1.7.1/deno-x86_64-unknown-linux-gnu.zip \
    && unzip deno.zip \
    && rm deno.zip

# install awscli which is used by s3 upload jobs
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install \
    && rm -rf ./aws awscliv2.zip

ENV AGENT_VERSION=4.3

RUN apt-get update && apt-get install git-lfs && rm -rf /var/lib/apt/lists/*

RUN curl --create-dirs -fsSLo /usr/share/jenkins/agent.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar \
  && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV AGENT_WORKDIR=/home/couchbase/agent
RUN mkdir -p ${AGENT_WORKDIR} \
  && chown couchbase:couchbase ${AGENT_WORKDIR}

# Set LANG
ENV LANG=en_US.UTF-8

# Expose SSH daemon and run our builder startup script
EXPOSE 22

# tini, to avoid zombie issues when running with Swarm jar
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY build/cb-buildbot-config.sh /usr/sbin/couchhook.d/
ENTRYPOINT [ "/tini", "--", "/usr/sbin/couchbuilder_start.sh" ]

# Avoid having to rebuild image chain for simple start script modifications
COPY build/couchbuilder_start.sh /usr/sbin/

# Hack because build-from-manifest script (and possibly others) hardcodes
# python3.6
RUN ln -s python3 /usr/bin/python3.6

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
