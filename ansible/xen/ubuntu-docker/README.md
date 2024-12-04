# Overview

This Ansible playbook will deploy a fresh Ubuntu 24.04.1 VM configured with:

 - default "couchbase" / "couchbase" user with sudo privs
 - most recent build of Docker
 - ssh, python, etc.
 - network configured via DHCP
 - optionally joined to a Docker Swarm
 - optionally with Docker Swarm node labels set
 - `/home/couchbase/jenkins` directory created (facilitates adding
   directly to a Jenkins Docker Swarm)
 - netdata installed and configured

# Requirements

## Local

The playbook assumes a file named `docker-config.json` exists locally,
and will copy it to `~/.docker/config.json` on the newly-created Ubuntu
host. This should contain credentials for a Docker Hub user such as
`nsbuildbot` that is in a paid organization on Docker Hub, to avoid rate
limiting when pulling images. See CBD-3656.

## Ansible

This works with the latest version of ansible-playbook, 2.18.0. It
requires the `ansible.posix` package installed from Ansible Galaxy, eg.

    ansible-galaxy collection install ansible.posix

I suggest installing ansible locally with `uv tool install ansible-core`.

## Xen

### Python3

The Xen host must have python3 available. Many of our Xen hosts are
based on an older XCP build with only python2, so I have manually
installed [Indygreg's Python Standalone
Build](https://github.com/indygreg/python-build-standalone) in
/opt/python on several of them.

    cd /opt
    wget https://github.com/indygreg/python-build-standalone/releases/download/20241016/cpython-3.10.15+20241016-x86_64-unknown-linux-gnu-install_only.tar.gz
    tar xf cpython*
    rm -f cpython*

To use this interpreter, we need to set `ansible_python_interpreter` to
the full path to the `python3` binary in `inventory`.

### Ubuntu ISO

IMPORTANT: It is assumed that the target Xen Server has an ISO Library
configured which contains "ubuntu-24.04.1-fully-automated.iso" (or
whatever image is named in the inventory's "install_iso" variable).
Instructions on creating that ISO are in the fully_automated_iso
subdirectory. You can configure this in XenCenter by navigating to the
"Storage" tab for the VM host and:

 - click "New SR"
 - select "NFS ISO" for the Type
 - provide any name; I recommend "NFS ISO Library (Ubuntu)"
 - you can leave "Autogenerate description based on SR settings" checked
 - provide the share name "cnt-s231.sc.couchbase.com:/data/buildteam/iso"
   and select NFSv3## Ansible

# Script invocation

There is a script "create-ubuntu-agent" which will run this playbook
with options specified on the command line. This is the recommended way
to use this playbook.

    Usage: create-ubuntu-agent -n NAME -x XEN_HOST -p XEN_PASSWORD
        [-m MEMORY] [-c CPUS] [-d DISKSPACE]
        [-r ROLES] [-e ROLE_ARG=VALUE]
        [-s SWARM_MANAGER] [-l SWARM_LABELS]
    Defaults: memory 20GB; cpus 8; diskpace 200GB; no Swarm

The options are:

 - `-p` - The root password of the Xen host (required)
 - `-d` - size of disk (in GiB) (required, but default value in
   inventory)
 - `-m` - memory allocated to VM (in GiB) (required, but default value
   in inventory)
 - `-c` - number of VCPUs allocated to VM (required, but default value
   in inventory)
 - `-n` - name of the VM in Xen. Will also be the VM's hostname so
   only use alphanumeric characters (required)
 - `-r` - comma-separated list of roles to apply to the newly-created
   VM.
 - `-e` - additional Ansible parameters, mostly required for roles
 - `-s` - IP address of a Docker Swarm manager to join (optional)
 - `-l` - Docker Swarm labels to apply to this new node (optional; if this
   is specified, swarm_manager must be as well)

The argument to `-l` must be a comma-separated list of key=value pairs,
with NO spaces anywhere. For instance, `-l "cvtype=ubuntu18,cvsize=large"`.


# Running without the convenience script

Not really recommended, but suggested incantation:

    ansible-playbook \
    -v -i inventory playbook.yml -e cmdline_password=secret \
      -e vm_name=mega4.7 -e memory=16 -e disksize=200 -e vcpus=8 \
      -e swarm_manager=172.23.1.1 -e swarm_labels="cvtype=ubuntu18" \
      -l xcp-s625,newvms

Specify `-l <xenserver host name>,newvms` to the ansible-playbook command line.
This will limit the creation of the new VM to the specified Xen Server. The
`,newvms` part is important to allow the second half of the playbook to execute
on the newly-created VM.

I've never tried creating VMs on multiple XenServers at the same time
with this; it probably won't work, and even if it did it would give them
all the same `vm_name`, which probably isn't what you want.

There are some additional fields you can set with `-e` on the
`ansible-playbook` command-line. The default values for these are in the
inventory, and are generally what you would want, which is why the
`create-ubuntu-agent` script doesn't directly support modifying these.

 - `install_iso` - If you create a different fully-automated image, name
 the .iso here
 - `network_name` - Use a different ethernet port on your Xen host
 - `sr_name` - create the VM on a different Storage Repository on the Xen host
