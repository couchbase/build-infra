# PREREQUISITES

This playbook seems to work with Ansible 2.13.9. It may not work with
earlier versions.

The remote Windows server needs to be ready for Ansible remote
control; see README.txt in the parent directory.

# PLAYBOOKS

playbook.yml installs everything necessary for creating a Couchbase Server
build slave. The rest of this document refers only to this playbook.

# LOCAL FILE MODIFICATIONS NECESSARY BEFORE RUNNING PLAYBOOK

The `inventory` file here is a stub to show the required format. Replace at
least the IP address(es) of the server(s) to configure.

Profile folder config+secrets will be pulled automatically at each boot,
you will need to pass the profile_sync key as an extra var, along with the
node product and class to enable this (e.g. product=couchbase-server
class=build)

# RUNNING THE PLAYBOOK

The primary playbook here is `playbook.yml`. It will install all toolchain requirements
for building Couchbase Server (spock release or later). It can be invoked via the `go`
script, e.g.:

./go [SSH_KEY] -e ansible_password=[password] -e vs2022_key=ABCD1234 -e NODE_PRODUCT=couchbase-server -e NODE_CLASS=build [-e targetvolume=d] [--tags all,visualstudio,testrunner]

`vskey` is the license key for Visual Studio Professional 2017 (omit any
dashes in the license key)
`SSH_KEY` is the path to the profile data synchronization key file the machine running `go` (see: lastpass)
`NODE_PRODUCT` is the product associated with this builder, e.g. couchbase-server
`NODE_CLASS` is the category of the worker, e.g. build, cv etc.

# THINGS THAT COULD GO WRONG

This playbook worked on April 26th 2023. It does not specify explicit versions
of any of the toolchain requirements, because many of the packages (notably
Visual Studio 2022 itself) are specifically designed to install only the
latest version. That being the case, things could change over time to make
this playbook fail.
