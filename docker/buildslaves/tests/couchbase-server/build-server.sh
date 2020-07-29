#!/bin/bash -xe

export WORKSPACE=/build
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -b|--build-number) BLD_NUM="$2"; shift ;;
        -d|--distro) DISTRO="$2"; shift ;;
        -e|--edition) EDITION="$2"; shift ;;
        -m|--manifest-file) MANIFEST_FILE="$2"; shift ;;
        -r|--manifest-repo) MANIFEST_REPO="$2"; shift ;;
        -v|--version) VERSION="$2"; shift ;;
        *) echo "Unrecognised parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "=========="
echo "MANIFEST_REPO=$MANIFEST_REPO"
echo "MANIFEST_FILE=$MANIFEST_FILE"
echo "EDITION=$EDITION"
echo "VERSION=$VERSION"
echo "BLD_NUM=$BLD_NUM"
echo "=========="

git config --global color.ui true
git config --global user.email build-team@couchbase.com
git config --global user.name "Build Team"

ssh-keyscan github.com >> ~/.ssh/known_hosts
git clone git@github.com:couchbase/build /cbbuild

MANIFEST_PARAMS="-u ${MANIFEST_REPO} -m ${MANIFEST_FILE}"

mkdir -p $WORKSPACE/artifacts && cd $WORKSPACE

repo init --no-repo-verify --repo-url=git://github.com/couchbasedeps/git-repo ${MANIFEST_PARAMS} -g all # --reference=~/reporef
repo sync --jobs=6 --quiet

export EXTRA_CMAKE_OPTIONS

VERSION=$(${WORKSPACE}/tlm/scripts/get_version.py | cut -d- -f1)
NEW_BLD_NUM=$((BUILD_NUMBER + 10000))
echo "VERSION=${VERSION}" > build.properties
echo "NEW_BLD_NUM=${NEW_BLD_NUM}" >> build.properties

echo "START COMPILE/PACKAGE ==== $(date)"
/cbbuild/scripts/jenkins/couchbase_server/server-linux-build.sh ${DISTRO} ${VERSION} ${EDITION} ${BLD_NUM}
echo "END === $(date)"

for ext in deb rpm
do
  mv *.$ext ${WORKSPACE}/artifacts || :
done
