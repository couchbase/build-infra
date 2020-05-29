# PREREQUISITES

This playbook seems to work with Ansible 2.5.0. It may not work with
earlier versions.

The remote Windows server needs to be ready for Ansible remote
control; see README.txt in the parent directory.

# PLAYBOOKS

playbook.yml installs everything necessary for creating a Couchbase SGW
build slave. The rest of this document refers only to this playbook.

# LOCAL FILE MODIFICATIONS NECESSARY BEFORE RUNNING PLAYBOOK

1. replace IP address(es) and ansible user name and password in the `inventory` file

# RUNNING THE PLAYBOOK

./go


# THINGS THAT COULD GO WRONG

This playbook worked on May 29th 2020.  That being the case, things could change over time to make
this playbook fail.
