The script in this directory can be used to create the
"ubuntu-18.04-fully-automated.iso" installation media that the playbook
depends on. To run it, you need to download
xe-guest-utilities_7.4.0-1_amd64.deb, which you can copy from the
"guest-tools.iso" image that can be mounted in any Xen VM via XenCenter.

If you find a later version of xe-guest-utilities, you'll need to modify
both mkfullyauto.sh and ks.cfg to reference the new filename.
