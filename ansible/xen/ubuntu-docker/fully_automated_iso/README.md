# Fully Automated Ubuntu ISO

The script in this directory can be used to create the
"ubuntu-22.04-fully-automated.iso" installation media that the playbook
depends on.

## Things you might need to adjust

I'm checking in the older xe-guest-utilities package as it appears to be the
only one which still works with XenServer 7.2, which is still in use here. If
you'd like to try updating in future, delete that .deb and the script will
attempt to download xe-guest-utilities from the GitHub releases. If this fails,
or you want to install a newer version that isn't on GitHub, you can copy the
file locally first. For instance, you can copy it from the "guest-tools.iso"
image that can be mounted in any Xen VM via XenCenter. In this case, you'll need
to modify mkfullyauto.sh to reference the new filename.

Note: the password for the couchbase user in nocloud/user-data is
"couchbase". If you ever want to use a different password, you can
create the hashed form with:

    echo mypassword | mkpasswd -m sha-512 -s

On Ubuntu, the "mkpasswd" command oddly comes in the "whois" pacakge.

## Notes

The "user-data" file is a [cloud-init config
file](https://cloudinit.readthedocs.io/en/latest/reference/modules.html),
except it really isn't because it's actually an [Ubuntu Server automated
installer config
file](https://ubuntu.com/server/docs/install/autoinstall-reference).

This is quite confusing because the two formats have a common ancestry and share
a number of keys in common, but use them in different ways. Basically, Subiquity
(the Ubuntu unattended-server installation tool) needs to get an configuration
file in the ubuntu autoinstall format, and the only way I could find to embed
such a file into an ISO was to embed it in a cloud-init file with the single
top-level key "autoinstall" and place it in a directory named "nocloud" at the
top level of the CDROM. This magic lets cloud-init use that file as a "nocloud"
datasource, and then somehow? subiquity extracts the actual config from there.

Anyway, I mention this only so that you know which documentation to look at if
you need to make changes in future. Don't try to use the cloud-init doc; it
won't work.
