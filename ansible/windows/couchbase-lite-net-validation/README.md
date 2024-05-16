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
       -v /home/couchbase/jenkinsdocker-ssh/:/mnt/ssh \
       couchbasebuild/ansible-playbook:2.7.4 \
       -i inventory playbook.yml -e ansible_password=PASSWORD \
       -e vs2015_key=KEY -e vs2017_key=KEY

# Manual Steps Required on VM After Playbook

After the playbook is run there are a few things that need to be set up manually that either cannot be handled automatically, or haven't been worked into the playbook yet, or are simply optional based on where this VM is going to be used.

## Windows 10 / Windows Server 2016+ only

### Running UWP applications

1. Enable [Developer Mode](https://docs.microsoft.com/en-us/windows/uwp/get-started/enable-your-device-for-development#accessing-settings-for-developers)
2. Install Oracle JRE (IcedTea is not compatible with Jenkins web start)
3. Add the certificate for your UWP project into the Local Machine -> Trusted People certificate store

## All Versions

### Building Xamarin Android applications
1. Install appropriate Android SDK Platform (e.g. API Level 26) for the app being built

### Using Powershell for network requests
1. Open Internet Explorer and choose recommended settings in the dialogue that appears.  Without this Powershell will not allow network downloads unless the `BasicParsing` option is specified.