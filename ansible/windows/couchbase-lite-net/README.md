# PREREQUISITES

This playbook likely requires at least Ansible 2.4.0 or greater.

The remote Windows server needs to be ready for Ansible remote
control; see README.txt in the parent directory.

Your local world needs to have Ansible installed (obviously) and configured
for controlling Windows hosts via WinRM, which means at least running

    pip install "pywinrm>=0.1.1"

See http://docs.ansible.com/ansible/intro_windows.html#installing-on-the-control-machine
for more details.

# PLAYBOOKS

playbook.yml installs everything necessary for creating a couchbase-lite-net
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
requirements for building couchbase-lite .NET

    docker run --rm -it -v ~/jenkinsdocker-ssh:/ssh -v`pwd`:/mnt \
           couchbasebuild/ansible-playbook \
           -i inventory playbook.yml \
           -e vskey=ABCD-EFGH-IJKL-MNOP \
           -e ansible_password=ADMINISTRATOR_PASSWORD

`vskey` is the license key for Visual Studio Professional 2017 (hyphen is included).
