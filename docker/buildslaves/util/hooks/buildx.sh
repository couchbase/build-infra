#!/bin/bash -ex

# This hook is used to ensure we are using a multi-arch capable builder
# moby/buildkit image version should be consistent w/ tonistiigi/binfmt
# "docker exec -it buildx_buildkit_cbmultiarch0 /usr/bin/buildkit-qemu-aarch64 --version"
# Ideally should match "tonistiigi/binfmt:qemu-<version>" installed on the host
# If they are too far apart, it could lead to undesired build corruption.
# Before upgrading qemu version, we need to make sure it is compatible with the OS and its glibc

# First be sure dockerd is available and writable by 'couchbase' user
if ! sudo -u couchbase find /var/run/docker.sock -writable ; then exit 0; fi

sudo -u couchbase --set-home --preserve-env \
  bash -c '
  set -ex;
  if docker buildx ls | awk "{print $1}" | tail -n +1 | grep cbmultiarch;
  then
    docker buildx rm cbmultiarch;
  fi;
  docker buildx create --name cbmultiarch --driver docker-container --driver-opt image=moby/buildkit:v0.23.2 --use --platform linux/amd64,linux/arm64;
  docker buildx inspect --bootstrap;
'
