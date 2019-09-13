# PREREQUISITES

This playbook likely requires at least Ansible 2.7.4.

The remote Windows server needs to be ready for Ansible remote
control; see README.txt in the parent directory.

Your local world needs to have Ansible installed (obviously) and configured
for controlling Windows hosts via WinRM, which means at least running

    pip install "pywinrm>=0.1.1"

See http://docs.ansible.com/ansible/intro_windows.html#installing-on-the-control-machine
for more details.

# PLAYBOOKS

playbook.yml installs everything necessary for creating the couchbase-lite-net
validation slave. The rest of this document refers only to this playbook.

# LOCAL FILE MODIFICATIONS NECESSARY BEFORE RUNNING PLAYBOOK

First, add any private key files necessary to the `ssh` directory. The
provided ssh/config file assumes that `buildbot_id_dsa` exists and can
be used to pull from Gerrit (necessary for commit-validation jobs), and
that a default key file such as `id_rsa` exists that can pull all private
GitHub repositories.

The `inventory` file here is a stub to show the required format. Replace at
least the IP address(es).

# RUNNING THE PLAYBOOK

The primary playbook here is `playbook.yml`.

    ansible-playbook -v -i inventory playbook.yml \
      -e ansible_password=ADMINISTRATOR_PASSWORD \
      -e vs2015_key=KEY -e vs2017_key=KEY

    Note: Visual Studio keys should have no dashes in them.

You can use our Docker image (recommended):

    docker run -it --rm -v $(pwd):/mnt -v $(pwd)/../roles:/mnt/roles \
       -v /home/couchbase/jenkinsdocker-ssh/:/ssh \
       couchbasebuild/ansible-playbook:2.7.4 \
       -i inventory playbook.yml -e ansible_password=PASSWORD \
       -e vs2015_key=KEY -e vs2017_key=KEY
