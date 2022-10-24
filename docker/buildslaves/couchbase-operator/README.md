This directory used to contain the Dockerfile for the image
couchbasebuild/ubuntu-2004-operator-build, which was used for all the
various "k8s" build and publish jobs.

Over time that image evolved to be based on buildx, and the
corresponding build agents began being used for a number of tasks
related to buildx, most notably including multi-arch builds of Couchbase
Server and Sync Gateway. So the image has been renamed
couchbasebuild/buildx (the corresponding Docker Stack was named buildx
some time ago), and is now located in ../buildx.

The subdirectory rhel-75 here is the Dockerfile for the much older image
localonly/redhat-75-couchbase-build, which exists only on a few internal
RHEL7 VMs.
