This Ansible playbook will deploy a fresh Ubuntu 22.04 VM configured with:

 - default "couchbase" / "couchbase" user with sudo privs
 - most recent build of Docker
 - ssh, python, etc.
 - network configured via DHCP
 - optionally joined to a Docker Swarm
 - optionally with Docker Swarm node labels set
 - /home/couchbase/jenkins directory created (facilitates adding directly to a
   Jenkins Docker Swarm)
 - netdata installed and configured

There is a script "create-ubuntu-agent" which will run this playbook with
options specified on the command line. You can also run the playbook
directly with "ansible-playbook" specifying the options with -e.

The options are:

 - cmdline_password: The root password of the Xen host (required)
 - disksize: size of disk (in GiB) (required, but default value in
   inventory)
 - memory: memory allocated to VM (in GiB) (required, but default value
   in inventory)
 - vcpus: number of VCPUs allocated to VM (required, but default value
   in inventory)
 - vm_name: name of the VM in Xen. Will also be the VM's hostname so
   only use alphanumeric characters (required, but default value in
   inventory)
 - roles: comma-separated list of roles to apply to the newly-created
   VM. If the role requires any Ansible variables to be set, you can
   specify them with the -e argument to either ansible-playbook or
   create-ubuntu-agent.
 - swarm_manager: IP address of a Docker Swarm manager to join
   (optional)
 - swarm_labels: Docker Swarm labels to apply to this new node
   (optional; if this is specified, swarm_manager must be as well)
 - install_iso: If you create a different fully-automated image (say,
   for Ubuntu 24 later), name the .iso here

swarm_labels must be a comma-separated list of key=value pairs, with NO spaces
anywhere. For instance, -e swarm_labels="cvtype=ubuntu18,cvsize=large".

You can also set network_name to select a different ethernet port on
your Xen host, and sr_name to select the Storage Repository to create
the new VM on. Generally the values specified in the inventory for each
Xen host are what you want. The convenience script "create-ubuntu-agent"
doesn't support setting these.

IMPORTANT: The playbook assumes a file named "docker-config.json" exists
locally, and will copy it to ~/.docker/config.json on the newly-created
Ubuntu host. This should contain credentials for a Docker Hub user such
as "nsbuildbot" that is in a paid organization on Docker Hub, to avoid
rate limiting when pulling images. See CBD-3656.

IMPORTANT: It is assumed that the target Xen Server has an ISO Library
configured which contains "ubuntu-22.04-fully-automated.iso" (or
whatever image is named in the inventory's "install_iso" variable).
Instructions on creating that ISO are in the fully_automated_iso
subdirectory. You can configure this in XenCenter by navigating to the
"Storage" tab for the VM host and:

 - click "New SR"
 - select "NFS ISO" for the Type
 - provide any name; I recommend "NFS ISO Library (Ubuntu)"
 - you can leave "Autogenerate description based on SR settings" checked
 - provide the share name "cnt-s231.sc.couchbase.com:/data/buildteam/iso"
   and select NFSv3

Suggested incantation:

  docker run --rm -v $(pwd):/mnt couchbasebuild/ansible-playbook \
    -v -i inventory playbook.yml -e cmdline_password=secret \
    -e vm_name=mega4.7 -e memory=16 -e disksize=200 -e vcpus=8 \
    -e swarm_manager=172.23.1.1 -e swarm_labels="cvtype=ubuntu18" \
    -l xcp-s625,newvms

NOTES

Specify "-l <xenserver host name>,newvms" to the ansible-playbook command line.
This will limit the creation of the new VM to the specified Xen Server. The
",newvms" part is important to allow the second half of the playbook to execute
on the newly-created VM.

I've never tried creating VMs on multiple XenServers at the same time with this
- it probably won't work, and even if it did it would give them the same
vm_name, which probably isn't what you want.
