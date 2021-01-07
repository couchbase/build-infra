#!/bin/bash -e
TAG=$(date +%Y%m%d)

for distro in amzn2 centos7 centos8 debian8 debian8-alice debian9 debian10 suse15 ubuntu16 ubuntu18 ubuntu20
do
  pushd $distro
  ./go

  for tag in ${TAG} latest
  do
    docker tag "couchbasebuild/server-${distro}-build:${TAG}" "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-${distro}-build:${tag}"
    docker push "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-${distro}-build:${tag}"
  done
  popd
done

pushd zz-lightweight
./go
docker tag couchbasebuild/zz-lightweight "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-zz-lightweight:latest"
docker tag couchbasebuild/zz-lightweight "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-zz-lightweight:${TAG}"
docker push "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-zz-lightweight:latest"
docker push "284614897128.dkr.ecr.us-east-1.amazonaws.com/server-zz-lightweight:${TAG}"
