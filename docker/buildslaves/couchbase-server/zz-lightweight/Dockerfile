# Docker container for zz-lightweight

FROM ubuntu:24.04
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

# /var/run/docker.sock from the host might be owned by group ID 999 (older
# Ubuntu 18-based host VMs) or 975 (newer custom Ubuntu 24-based host VMs).
# Create our own groups for those here in the container image. Do this early,
# because some later package installations might create those group IDs.
RUN set -x \
    && groupadd --gid 999 docker \
    && groupadd --gid 975 docker975

# Ubuntu 24 has a default 'ubuntu' user with UID/GID 1000, which we need
# to be 'couchbase'. Fix that up, grant password-less sudo privs, and
# give ownership of /opt/couchbase
RUN set -x \
    && apt-get update \
    && apt-get install -y sudo \
    && apt-get clean \
    && groupmod --new-name couchbase ubuntu \
    && usermod --login couchbase -d /home/couchbase -m \
           -g couchbase -G sudo,docker,docker975 -s /bin/bash ubuntu \
    && mkdir -p /opt/couchbase && chown -R couchbase:couchbase /opt/couchbase \
    && echo 'couchbase:couchbase' | chpasswd \
    && sed -ri 's/ALL\) ALL/ALL) NOPASSWD:ALL/' /etc/sudoers

# Install required apt packages, i.e. build-essential, sudo, curl, common, SSHD, apt-utils
RUN set -x \
    && apt-get update \
    && apt-get install -y \
       apt-utils \
       build-essential \
       curl \
       software-properties-common \
       unzip \
       zip \
    && apt-get clean \
    && apt-get autoremove --purge -y \
    && apt-get clean

# JDK for Jenkins
RUN set -x \
    && apt-get update \
    && apt-get install -y openjdk-17-jre-headless \
    && apt-get clean

# Utilities that are handy for zz-lightweight jobs and occasional interactive use
RUN set -x \
    && apt-get update \
    && apt-get install -y jq vim \
    && apt-get clean

# Install git and repo
RUN set -x \
    && apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && curl --fail https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod a+x /usr/local/bin/repo

# Install rsync
RUN set -x \
    && apt-get update \
    && apt-get install -y rsync \
    && apt-get clean

# Install rvm so that we can use it to upgrade ruby when necessary
RUN set -x \
    && groupadd rvm \
    && sudo apt-add-repository -y ppa:rael-gc/rvm \
    && sudo apt-get update \
    && sudo apt-get install -y rvm \
    && apt-get clean

# Install Deno for running javascript
RUN set -x \
    && cd /usr/local/bin \
    && curl --fail -Lo deno.zip https://github.com/denoland/deno/releases/download/v1.7.1/deno-x86_64-unknown-linux-gnu.zip \
    && unzip deno.zip \
    && rm deno.zip

# Install awscli which is used by s3 upload jobs
RUN curl --fail "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install \
    && rm -rf ./aws awscliv2.zip

# Install azure-cli, which is used for building and processing Azure images
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install gcloud for building and processing GCP images
RUN set -x \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
      | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt-get update \
    && apt-get install -y google-cloud-cli \
    && apt-get clean

# Install packer script, which is used for building AWS/Azure/GCP images
RUN set -x \
    && cd /usr/local/bin \
    && curl --fail https://releases.hashicorp.com/packer/1.8.1/packer_1.8.1_linux_amd64.zip -o packer.zip \
    && unzip packer.zip \
    && chmod +x packer \
    && rm packer.zip

# Install rclone, createrepo, rpm, and aptly for managing yum/apt repos
RUN set -x \
    && curl --fail "https://downloads.rclone.org/v1.61.1/rclone-v1.61.1-linux-amd64.deb" -o /tmp/rclone.deb \
    && apt-get update \
    && apt-get install -y createrepo-c aptly rpm expect /tmp/rclone.deb \
    && apt-get clean \
    && rm /tmp/rclone.deb

# Docker CLI, buildx, and skopeo
COPY --from=docker/buildx-bin:latest /buildx /usr/libexec/docker/cli-plugins/docker-buildx
RUN set -x \
    && apt-get update \
    && apt-get install -y apt-transport-https \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli skopeo \
    && apt-get clean
RUN set -x \
    && mkdir -p /home/couchbase/.docker \
    && chown couchbase:couchbase /home/couchbase/.docker

# Install rye as user couchbase, so jobs can manage ~/.rye as needed
USER couchbase
RUN set -x \
    && curl -L https://github.com/astral-sh/rye/releases/latest/download/rye-x86_64-linux.gz \
    | gzip -dc > /tmp/rye \
    && chmod 755 /tmp/rye \
    && /tmp/rye self install --toolchain-version=3.10 --yes \
    && rm /tmp/rye

# Install UV as user couchbase also.
RUN set -x \
    && cd /tmp \
    && curl -LO https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz \
    && tar xf uv-x86_64-unknown-linux-gnu.tar.gz \
    && mkdir -p /home/couchbase/.local/bin \
    && cp -a uv-x86_64-unknown-linux-gnu/* /home/couchbase/.rye/shims \
    && rm -rf uv-x86_64-unknown-linux-gnu.tar.gz uv-x86_64-unknown-linux-gnu

USER root

# Ensure uv and Rye's shims are on agents' PATH so they have a proper `python` command
RUN echo "/home/couchbase/.local/bin:/home/couchbase/.rye/shims" >> /etc/path

# Set LANG
ENV LANG=en_US.UTF-8

# Expose SSH daemon and run our builder startup script
EXPOSE 22
ENTRYPOINT [ "/usr/sbin/couchbuilder_start.sh" ]
CMD ["swarm"]

# Avoid having to rebuild image chain for simple start script modifications
COPY build/couchbuilder_start.sh /usr/sbin/
COPY build/swarm*.properties /

# Keep this stuff at the end, because the ARG declaration breaks
# Docker build caching
ARG CONTAINER_TAG_ARG
ENV CONTAINER_TAG=${CONTAINER_TAG_ARG}
