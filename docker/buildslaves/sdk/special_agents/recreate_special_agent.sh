#!/bin/bash -ex

AGENT=$1
DOCKER_VERSION=27.3.1
JQ_VERSION=1.7.1

echo Installing Docker...
cbdep install docker ${DOCKER_VERSION}

echo Installing jq...
cbdep install jq ${JQ_VERSION}

export PATH=$(pwd)/install/jq-${JQ_VERSION}/bin:$(pwd)/install/docker-${DOCKER_VERSION}/bin:$PATH

echo Removing old ${AGENT} agent...
docker --host sdk-swarm-01.build.couchbase.com rm -f ${AGENT} || true

echo Creating new ${AGENT} agent...
# Note: the : at the end of JENKINS_TUNNEL is important, not a typo!
container_full=$(docker --host sdk-swarm-01.build.couchbase.com \
    run --pull always -d --privileged --restart=unless-stopped \
    --memory-reservation 4g \
    --name ${AGENT} \
    -e JENKINS_MASTER=https://sdk.jenkins.couchbase.com/ \
    -e JENKINS_TUNNEL=mega4.build.couchbase.com: \
    -e JENKINS_SLAVE_NAME=build-${AGENT} \
    -e JENKINS_SLAVE_LABELS=${AGENT} \
    -v /home/couchbase/SPECIAL_SLAVES/jenkins_master_username:/run/secrets/jenkins_master_username \
    -v /home/couchbase/SPECIAL_SLAVES/jenkins_master_password:/run/secrets/jenkins_master_password \
    couchbasebuild/sdk-${AGENT}:latest \
    swarm)
container=$(echo ${container_full} | cut -c1-12)

# Avoid echoing passwords to the log
set +x
jenkins_auth="$(cat /run/secrets/jenkins_master_username):$(cat /run/secrets/jenkins_master_password)"

echo Checking agent came online...
for i in {1..5}; do
    sleep 5
    offline=$( \
        curl --globoff -s -u "${jenkins_auth}" \
        'https://sdk.jenkins.couchbase.com/computer/api/json?tree=computer[displayName,offline]&pretty=true' | \
        jq '.computer[] | select(.displayName == "'build-${AGENT}-${container}'") | .offline' \
    )
    if ${offline}; then
        if [ "${i}" -eq 5 ]; then
            echo "Agent ${AGENT} failed to start; removing! Logs:"
            docker --host sdk-swarm-01.build.couchbase.com logs ${AGENT}
            docker --host sdk-swarm-01.build.couchbase.com rm -f ${AGENT}
            exit 1
        fi
        echo "Agent ${AGENT} not yet running, still waiting..."
    else
        echo "Agent ${AGENT} is online!"
        break
    fi
done
