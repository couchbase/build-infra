# This Dockerfile exists only to update the Jenkins Swarm jar in the
# existing Docker image. We don't want to rebuild some of the older
# historic images and risk raising unexpected issues when rebuilding
# older releases. The file Dockerfile.historic is the Dockerfile that
# the image was originally build from.

FROM couchbasebuild/server-suse11-build:20180713

ADD build/swarm-client-3.17.jar /usr/local/lib/swarm-client.jar
