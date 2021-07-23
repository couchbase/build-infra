We initially built gcc and Server build containers for RHEL8 based on UBI8 for
the Alice release, so that Server could be part of Red Hat's RHEL8 launch
festivities. At the time we did the RHEL subscription-manager stuff and then
pushed those images to Docker Hub, which was probably bad. Later we started
pushing newer images to build-docker.couchbase.com instead. I have deleted the
older images from Docker Hub.

Now that we're switching away from Centos 8 for Cheshire-Cat and later, we're
re-doing those images more correctly, based on pure UBI with no subscription
manager. Just in case we ever need to update the Alice versions, though, I'm
copying the original Dockerfile and other files into this "alice" directory
for reference.

For the Server build container, the initial version had several tags, the
latest of which was :20190524. After that, a year later we needed to update it
for Docker Swarm compatibility, but since Alice was post-GA we instead
extended the existing image to avoid surprises from completely rebuilding it.
The Dockerfile used to create the initial container images is saved here as
Dockerfile.historic, while the file "Dockerfile" is the extension we did for
Swarm etc. All of the images from these Dockerfiles only exist on
build-docker.couchbase.com now.
