# PREREQUISITES

This playbook seems to work with Ansible 2.5.0. It may not work with
earlier versions.

The remote Windows server needs to be ready for Ansible remote
control; see README.txt in the parent directory.

Your local world needs to have Ansible installed (obviously) and configured
for controlling Windows hosts via WinRM, which means at least running

    pip install "pywinrm>=0.1.1"

See http://docs.ansible.com/ansible/intro_windows.html#installing-on-the-control-machine
for more details.

# PLAYBOOKS

playbook.yml installs everything necessary for creating a Couchbase Server
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

    ansible-playbook -v -i inventory playbook.yml \
      -e vskey=ABCDEFGHIJKLMNOPQRSTUVWYZ \
      -e ansible_password=ADMINISTRATOR_PASSWORD

or

    docker run --rm -it -v $(pwd):/mnt couchbasebuild/ansible-playbook:2.7.4 \
      -v -i inventory playbook.yml \
      -e vskey=ABCDEFGHIJKLMNOPQRSTUVWYZ \
      -e ansible_password=ADMINISTRATOR_PASSWORD

`vskey` is the license key for Visual Studio Professional 2017 (omit any
dashes in the license key).

# THINGS THAT COULD GO WRONG

Installing the "py2exe" package via easy_install, seems to fail consistently
even though it seems to install correctly. I've put an ignore_error to
temporarily bypass this issue.

This playbook worked on Dec 07, 2018. It does not specify explicit versions
of any of the toolchain requirements, because many of the packages (notably
Visual Studio 2017 itself) are specifically designed to install only the
latest version. That being the case, things could change over time to make
this playbook fail.
