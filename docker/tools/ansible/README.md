Docker image for running Ansible playbooks
------------------------------------------

Suggested usage:

  docker --rm -it -v ~/.ssh:/ssh -v `pwd`:/mnt couchbasebuild/ansible-playbook -i inventory playbook.yml

Does two things:

1. Copies anything from /ssh to the root user's ~/.ssh, so you can use your
local ssh keys and configuration for connecting to Ansible guests

2. If /mnt contains a "requirements.yml", runs ansible-galaxy -r requirements.yml
to load necessary roles.

3. Runs ansible-playbook in the /mnt directory, so if you mount $PWD to /mnt
you can run playbooks in your local working directory

The image includes Ansible, WinRM, and sshpass.

