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

For GCC, I've re-tagged the historic version as
build-docker.couchbase.com/couchbasebuild/rhel-8-gcc:7.3.0-alice . The newer
versions will only be uploaded to Docker Hub, not build-docker, but it seemed
best to ensure that the tags did not conflict.
