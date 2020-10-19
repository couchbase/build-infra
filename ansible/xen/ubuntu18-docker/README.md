This Ansible playbook will deploy a fresh Ubuntu 18.04 VM configured with:

 - default "couchbase" / "couchbase" user with sudo privs
 - most recent build of Docker
 - ssh, python, etc.
 - network configured via DHCP

IMPORTANT: The playbook assumes a file named "docker-config.json" exists
locally, and will copy it to ~/.docker/config.json on the newly-created
Ubuntu 18.04 host. This should contain credentials for a Docker Hub user
such as "nsbuildbot" that is in a paid organization on Docker Hub, to
avoid rate limiting when pulling images. See CBD-3656.

Note: It is assumed that the target Xen Server has an ISO Library configured
which contains "ubuntu-18.04-fully-automated.iso". Instructions on creating
that ISO are in the fully_automated_iso subdirectory. You can configure this
in XenCenter by navigating to the "Storage" tab for the VM host and:

 - click "New SR"
 - select "NFS ISO" for the Type
 - provide any name; I recommend "NFS ISO Library (Ubuntu)"
 - you can leave "Autogenerate description based on SR settings" checked
 - provide the share name "cnt-s231.sc.couchbase.com:/data/buildteam/iso"
   and select NFSv3

The ssh password for the Xen host must be specified on the command line
in the variable cmdline_password.

You should also specify a custom value for vm_name. This will be used for
the hostname of the new VM, including DNS, so don't include odd characters
like periods or underscores.

The default values for memory, disk size, and number of CPUs are in
'inventory', and can be overridden on the command line. You can also
set network_name to select a different ethernet port on your Xen host, and
sr_name to select the Storage Repository to create the new VM on.

Suggested incantation:

  docker run --rm -v $(pwd):/mnt couchbasebuild/ansible-playbook \
    -v -i inventory playbook.yml -e cmdline_password=secret \
    -e vm_name=mega4.7

NOTES

Don't run this with an inventory containing more than one uncommented
VM host IP. The "add_host" functionality to add the new VM to the
"newvms" Ansible group apparently doesn't work when multiple hosts are
created at once.

Don't try getting around this by using -l on the ansible-playbook
command line. That will filter out the new hosts entirely.
