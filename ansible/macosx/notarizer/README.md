This playbook deploys the notarization service on the systems targeted in the inventory.

Note: There is an assumption that the target system has the signing certificate already (e.g. was deployed as a build node)

ansible-playbook -i inventory playbook.yml  -e ansible_ssh_pass=<jenkins_password> --ask-become-pass
