The script in this directory can be used to create the
"ubuntu-22.04-fully-automated.iso" installation media that the playbook
depends on.

It attempts to download xe-guest-utilities_7.10.0-0ubuntu1_amd64.deb
from the Ubuntu archives. If this fails in future, or you want to
install a newer version that isn't in the archives, you can copy the
file locally first. For instance, you can copy it from the
"guest-tools.iso" image that can be mounted in any Xen VM via XenCenter.
In this case, you may need to modify mkfullyauto.sh to reference the new
filename.

Note: the password for the couchbase user in nocloud/user-data is
"couchbase". If you ever want to use a different password, you can
create the hashed form with:

    echo mypassword | mkpasswd -m sha-512 -s

On Ubuntu, the "mkpasswd" command oddly comes in the "whois" pacakge.
