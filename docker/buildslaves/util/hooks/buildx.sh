#!/bin/bash -ex

# This hook is used to ensure we are using a multi-arch capable builder
# and the relevant platform emulation is available

MULTIARCH_IMG=multiarch/qemu-user-static
MULTIARCH_SHA=2c8b8fcf1d6badfca797c3fb46b7bb5f705ec7e66363e1cfeb7b7d4c7086e360

if docker buildx ls | awk '{print $1}' | tail -n +1 | grep cbmultiarch
then
  docker buildx use cbmultiarch --default
else
  docker run --rm --privileged ${MULTIARCH_IMG}@sha256:${MULTIARCH_SHA} --reset -p yes
  docker buildx create --name cbmultiarch --driver docker-container --use
  docker buildx inspect --bootstrap
fi
