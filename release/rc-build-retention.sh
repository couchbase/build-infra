#!/bin/bash -e
# Program to retain release candidate build a bit longer or expire them on NAS

usage() {
    echo
    echo "$0 -p <product> -r <release> -b <bld_num> -k <true|false>"
    echo
    echo "  -p: product name; couchbase-server"
    echo "  -r: release name; mad-hatter"
    echo "  -b: build number; 3410"
    echo "  -k: keep build; true set to keep, false set to remove"
}

while getopts "p:r:b:k:" opt; do
    case $opt in
        p) PRODUCT=$OPTARG;;
        r) RELEASE=$OPTARG;;
        b) BLD_NUM=$OPTARG;;
        k) KEEP_BUILD=$OPTARG;;
        h|?) usage
           exit 0;;
        *) echo "Invalid argument $opt"
           usage
           exit 1;;
    esac
done

if [ ! "${PRODUCT}" ] || [ ! "${RELEASE}" ] || [ ! "${BLD_NUM}" ] || [ ! "${KEEP_BUILD}" ]; then
    usage
    exit 1
fi

CURRENT_DIR=$(pwd)
LB_MOUNT=/latestbuilds
LATESTBUILDS=${LB_MOUNT}/${PRODUCT}/${RELEASE}/${BLD_NUM}
GIT_DIR='rc-build-retention'

if [ ! -e ${LATESTBUILDS} ]; then
    echo "\"${LATESTBUILDS}\" directory is not available!"
    exit 1
fi

pushd ${LATESTBUILDS}
files=$(ls)
IFS=$'\n'
popd

# Modify to current timestamp
mark_file_current() {
    pushd ${LATESTBUILDS}
    for f in ${files}
    do
        touch -a -m "${f}"
    done
    popd
}

# Modify to expired timestamp: "Unix epoch is 1970-01-01T00:00:00Z"
mark_file_outdated() {
    pushd ${LATESTBUILDS}
    for f in ${files}
    do
        touch -a -m -d '-15 day' "${f}"
    done
    popd
}

# Add bld_num to git repo
add_git_file() {
    pushd ${CURRENT_DIR}/${GIT_DIR}/
    mkdir -p ${CURRENT_DIR}/${GIT_DIR}/${PRODUCT}/${RELEASE}
    touch ${CURRENT_DIR}/${GIT_DIR}/${PRODUCT}/${RELEASE}/${BLD_NUM}
    git add ${PRODUCT}/${RELEASE}/${BLD_NUM}
    git commit -m "retain RC build - ${PRODUCT}/${RELEASE}/${BLD_NUM}"
    git push origin master:refs/heads/master
    popd
}

# Remove bld_num to git repo
remove_git_file() {
    pushd ${CURRENT_DIR}/${GIT_DIR}/
    git rm ${PRODUCT}/${RELEASE}/${BLD_NUM}
    git commit -m "remove RC build - ${PRODUCT}/${RELEASE}/${BLD_NUM}"
    git push origin master:refs/heads/master
    popd
}

if [[ ${KEEP_BUILD} == 'true' ]]; then
    mark_file_current
    if [[ ${DAILY_RUN} == 'false' ]];then
        add_git_file
    fi
elif [[ ${KEEP_BUILD} == 'false' ]]; then
    mark_file_outdated
    remove_git_file
else
    echo "KEEP_BUILD is set to an unknown value \"${KEEP_BUILD}\"!"
    echo "Nothing to do!"
    exit 0
fi
