# PREREQUISITES

This playbook requires to run from couchbasebuild/ansible-playbook:2.7.4 Docker container

The remote Windows server needs to be ready for Ansible remote
control; see README.txt in the parent directory.

# PLAYBOOKS

playbook.yml installs everything necessary for creating erlang window
build slave. The rest of this document refers only to this playbook.

# LOCAL FILE MODIFICATIONS NECESSARY BEFORE RUNNING PLAYBOOK

First, add any private key files necessary to the `ssh` directory. The
provided ssh/config file assumes that `buildbot_id_dsa` exists and can
be used to pull from Gerrit (necessary for commit-validation jobs), and
that a default key file such as `id_rsa` exists that can pull all private
GitHub repositories.

The `inventory` file here is a stub to show the required format. Replace at
least the IP address(es) of the server(s) to configure.

`vskey` is the license key for Visual Studio Professional 2013 (omit any
dashes in the license key).

# RUNNING THE PLAYBOOK

The primary playbook here is `playbook.yml`. It will install all toolchain
requirements for building Couchbase Server (spock release or later).

    docker run --rm -it -v $(pwd):/mnt couchbasebuild/ansible-playbook:2.7.4 \
      -v -i inventory playbook.yml \
      -e vskey=ABCDEFGHIJKLMNOPQRSTUVWYZ \
      -e ansible_password=ADMINISTRATOR_PASSWORD
