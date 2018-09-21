Ansible playbook for configuring a base Ubuntu 16.04/18.04 server image
with Docker.

Pre-requisites:
 - assumes a user "couchbase" with password "couchbase" and sudo privs
 - requires python to be installed (tested with "python" package - out of the
   box, Ubuntu 16.04 server has only python3 installed)

"go" is a convenience script to run this playbook.

Update 2018-09-21: Confirmed that it is safe to re-run this playbook to
update the system with the latest version of Docker.

