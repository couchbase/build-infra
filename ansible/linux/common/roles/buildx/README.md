# couchbase-cloud-runner

This Ansible role adds a service whose function is to ensure additional
emulator binaries required for doing multi-arch builds are available
to buildx. These emulator binaries do not persist a reboot, so must be
reapplied each time the server restarts.
