#!/bin/bash -ex

# This hook is used to ensure we are using a multi-arch capable builder

sudo -u couchbase --set-home --preserve-env \
  env -u jenkins_user -u jenkins_password -u SUDO_UID -u SUDO_GID -u SUDO_USER -u SUDO_COMMAND \
  bash -c '
  set -ex;
  test -d ~/.ssh || mkdir ~/.ssh;
  test -f "~/.ssh/known_hosts" && ssh-keygen -R 10.100.151.12;
  ssh-keyscan -H 10.100.151.12 >> ~/.ssh/known_hosts;
  if docker buildx ls | awk "{print $1}" | tail -n +1 | grep cbmultiarch;
  then
    docker buildx rm cbmultiarch;
  fi;
  docker buildx create --name cbmultiarch --driver docker-container --use --platform linux/amd64;
  docker buildx create --name cbmultiarch --driver docker-container --use --append ssh://buildx-arm64 --platform linux/arm64;
  docker buildx inspect --bootstrap;
'
