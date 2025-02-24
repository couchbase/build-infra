# Debian XCP Template

## What's this?

This directory contains packer scripts to create a simple Debian VM
template on an XCP host. This template:

- has a `couchbase` user as UID 1000, which:
  - is in group `couchbase` with GID 1000
  - has password-less `sudo` privs
  - has the password `couchbase`
  - has `id_buildteam.pub` in its ssh `authorized_keys`
- has the latest `xen-guest-agent` utilities installed [(the newer
  Rust-based tools)](https://gitlab.com/xen-project/xen-guest-agent)
- has basic tools installed, including sshd, curl, iptables, net-tools
- has `cloud-initramfs-growroot` installed, such that when a new VM is
  created from the template, it will automatically grow the root FS to
  use all disk space given to the VM
- does NOT have `cloud-init` installed, as that mechanism on self-hosted
  VMs still seems to be a complete mess of mutually-incompatible tools
- has `netdata` installed and running, and exposed on port 19999

## Why's this?

This is meant as a replacement of the "fully-automated" Ubuntu ISO
solution. The main reasons for the change are:

- Switching to a XCP template vs. an `.iso` allows for much faster VM
  creation
- Debian's `preseed` approach for automating VM installs is at least
  somewhat more straightforward than Ubuntu's very messy
  cloud-init-based `autoinstall` stuff (although they're both horribly
  undocumented Frankenstein monsters)
- Using the packer XCP plugin is (maybe) easier to maintain than the
  Ansible-based XCP automation
- Switching to Debian vs. Ubuntu fixes a long-standing problem where
  rebooting several VMs at once would frequently cause them to shuffle
  their IP addresses. This ultimately turned out to be because Ubuntu
  has networking config to release DHCP leases on reboot
- These Debian templates don't include Docker, as they're primary
  intended to serve as a basis for new Kubernetes cluster nodes

## Usage

Copy `variables.auto.pkrvars.hcl.example` to
`variables.auto.pkrvars.hcl`, and modify for the specific XCP host you
wish to create the template on. If the host you're using doesn't have a
block in `hosts.pkr.hcl` yet, you'll need to add one.

Also ensure that there isn't already a template in Xen Orchestra with
the same name as you're about to create - see the naming convention
information below under "XCP host notes". Since the template VM's name
includes the XCP pool name, each template should have a unique name.
named. However if you're re-creating the template after updating this
repository, be sure to delete the existing template first.

Then just run `./go`.

This will copy the `preseed.cfg` over to the NAS (via ssh'ing to
`mega3`) as I couldn't find another way to pass it in to the VM via
Packer. `cd_files` didn't work, `floppy_files` didn't seem to work and
causes a lengthy hang at startup, `http_files` doesn't work from a
laptop via the VPN.

The `id_buildteam.pub` file is already on the NAS. The corresponding
private ssh key is in 1password as `id_buildteam SSH key`.

## XCP host notes

Since each of our XCP hosts has its own pool, the template unfortunately
needs to be created for each one individually. For the corresponding
Terraform VM-creation mechanism, the template needs to be named exactly

    Debian X.Y.Z Template - <XCP pool name>

eg. the one for xcp-se29 is named `Debian 12.9.0 Template - Build -
xcp-se29`. This script does assume that all pools are named exactly
"Build - <XCP host name>", eg. "Build - xcp-se29".

This is necessary for the Terraform automation because templates need to
be named uniquely across all of Xen Orchestra, and because we need to
find the correct template for the XCP pool we're creating new VMs in.

I have set the template to have only a 4GB disk so it doesn't take much
space.

## Debian version notes

The Packer scripting tries to be agnostic about the specific Debian
version. However, it is assumed that the preseed file will need to
change over time, at least with major Debian changes. So since we
currently are working with Debian 12.9.0, the preseed file is named
`debian12.cfg`. The Packer config will look up the appropriate preseed
file based on the major Debian version.

When we start working with Debian 13, we need to first create
`preseed/debian13.cfg`.

## Debian ISO notes

This script will look for the appropriate Debian .iso on the XCP SR
named by `sr_iso_name` in `debian.pkr.hcl`, which is set to "NFS ISO
library (Buildteam)". If it doesn't find the ISO in that SR, it will
download it locally and then upload it to the SR.

However, currently the XCP packer plugin has a bug whereby the uploaded
`.iso` is given an opaque hash-based filename, meaning that the script
won't find it when the script is re-run. So if you run this for the
first time for a new Debian version, after running, go to the
`/data/builds/iso` directory on the NAS and rename the wrongly-named
`.iso` to `debian-X.Y.Z-amd64-netinst.iso`.

If you are creating a template on a new Xen host which does not have the
above NFS SR, here is how to create it using Xen Orchestra:
 - Navigate to the "Storage" tab for the VM host
 - Click "+ Add a storage"
 - Enter something like "NFS ISOs (buildteam) for both Name and Description
 - Select "NFS ISO" for the Type
 - Under settings, enter "cnt-s231.sc.couchbase.com" for Server and click the
   magnifying glass on the right of that field
 - Drop down the "Path" option and select `/data/builds`
 - Enter "iso" for Subdirectory and click the little magnifying glass on
   the right of that field
 - This should cause the "Summary" section to populate, so now you can
   click "Create"
