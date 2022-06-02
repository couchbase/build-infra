This folder exists purely for reference to show what couchbasebuild/amzn-2-gcc:7.3.0-aarch64 is comprised of - that image should never change, so this image will never need to be rebuilt.

7.3.0-x86_64 is a straightforward re-tag of the old :7.3.0, some simple logic exists in `go` to prevent the x86_64 image being accidentally replaced if anybody ever does need to retrigger this for some reason and does so on the wrong architecture.

We also include the `docker manifest` commands that were run to create the multi-arch :7.3.0 tag.