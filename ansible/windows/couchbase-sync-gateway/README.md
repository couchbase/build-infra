# PREREQUISITES

This playbook requires to run from couchbasebuild/ansible-playbook Docker container

The remote Windows server needs to be ready for Ansible remote
control; see README.txt in the parent directory.

# PLAYBOOKS

prep-for-installer.yml prepares a VM for SGW 2.0 MSI window build, meaning
it ensures the MS Universal CRT (UCRT) is installed and that remote desktop
is appropriately set up. That's all it does.

sgw.yml install to the VM with all required core tools for window VM Jenkins slave
pip.yml install to the VM with required pip tools for window VM Jenkins slave
go.yml install to the VM with required go tools for window VM Jenkins slave

playbook.yml installs everything necessary for creating SGW window
build slave. The rest of this document refers only to this playbook.

# LOCAL FILE MODIFICATIONS NECESSARY BEFORE RUNNING PLAYBOOK

First, add any private key files necessary to the `ssh` directory. The
provided ssh/config file assumes that `buildbot_id_dsa` exists and can
be used to pull from Gerrit (necessary for commit-validation jobs), and
that a default key file such as `id_rsa` exists that can pull all private
GitHub repositories.

The `inventory` file here is a stub to show the required format. Replace at
least the IP address(es) of the server(s) to configure.

# RUNNING THE PLAYBOOK

The primary playbook here is `playbook.yml`. It will install all toolchain
requirements for building Couchbase Server (spock release or later).


    docker run --rm -it -v ~/jenkinsdocker-ssh:/ssh -v`pwd`:/mnt couchbasebuild/ansible-playbook \
                        -i inventory playbook.yml
                        -e ansible_password=ADMINISTRATOR_PASSWORD
