"Docker From Scratch"
---------------------

This Dockerfile and associated scripts builds a Docker image from
nothing, using the techniques of [Linux From
Scratch](https://www.linuxfromscratch.org/lfs/). The current version is
based on LFS 12.3.

The resulting image has close to the minimum set of software installed
to operate as a Docker image, plus GCC, binutils, make, curl, git, and a
few other packages that are frequently required for building other Linux
software.

The important goal of this was to allow us to create builder images with
arbitrary glibc versions and GCC version(s). In particular, the current
default build will include glibc 2.28 and GCC 13.2.0. This can then
become the base for a full builder image for Couchbase Server Morpheus
and newer, where we no longer support any Linux distros that ship with
glibc lower than 2.28.

Building this image takes considerable time as the Linux From Scratch
approach requires building a number of packages multiple times,
including building GCC three times.
