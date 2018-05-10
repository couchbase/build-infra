This Ansible playbook will deploy a fresh Ubuntu 18.04 VM configured with:

 - default "couchbase" / "couchbase" user with sudo privs
 - most recent build of Docker
 - ssh, python, etc.
 - network configured via DHCP

Note: It is assumed that the target Xen Server has an ISO Library configured
which contains "ubuntu-18.04-fully-automated.iso". Instructions on creating
that ISO are in the fully_automated_iso subdirectory.

The ssh password for the Xen host must be specified on the command line
in the variable cmdline_password. You should also specify a custom value for
vm_name.

The default values for memory, disk size, and number of CPUs are in
xenserver_vars.yml, and can be overridden on the command line. You can also
set network_name to select a different ethernet port on your Xen host, and
sr_name to select the Storage Repository to create the new VM on.

Suggested incantation:

  docker run --rm -v $(pwd):/mnt couchbasebuild/ansible-playbook \
    -v -i inventory playbook.yml -e cmdline_password=secret \
    -e vm_name=mega4.7
