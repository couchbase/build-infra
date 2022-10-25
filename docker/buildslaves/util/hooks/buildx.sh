#!/bin/bash -ex

# This hook is used to ensure we are using a multi-arch capable builder

# First be sure dockerd is available and writable by 'couchbase' user
if ! sudo -u couchbase find /var/run/docker.sock -writable ; then exit 0; fi

sudo -u couchbase --set-home --preserve-env \
  bash -c '
  set -ex;
  test -d ~/.ssh || mkdir ~/.ssh;
  test -f "~/.ssh/known_hosts" && ssh-keygen -R buildx-arm64-01.build.couchbase.com;
  ssh-keyscan -H buildx-arm64-01.build.couchbase.com >> ~/.ssh/known_hosts;
  if docker buildx ls | awk "{print $1}" | tail -n +1 | grep cbmultiarch;
  then
    docker buildx rm cbmultiarch;
  fi;
  docker buildx create --name cbmultiarch --driver docker-container --use --platform linux/amd64;
  docker buildx create --name cbmultiarch --driver docker-container --use --append ssh://buildx-arm64-01 --platform linux/arm64;
  docker buildx inspect --bootstrap;
'
