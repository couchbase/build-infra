Setup Server MACOS

Prereq
1. IP address of a running macOS target

Deploy tools via ansible
1. Ensure the IP address is present in the inventory file
2. Enable `Remote Login` in `Settings/Sharing`
3. Add the host key to your known_hosts file by sshing to the target or using ssh-keyscan
4. Run `sudo xcode-select --install` to ensure python3 is present for Ansible (note: you'll need to click a button in the gui to continue)
5. Run the playbook specifying password where required

    `$ ansible-playbook -i inventory playbook.yml -e "ansible_ssh_pass=<jenkins_pass> -e XCODE_VERSION=<version>" --ask-become-pass`

Note: Tagging is used at role and block level to ease debugging. For instance use --limit=software to limit your run to performing all the tasks in the software role, or you could use --limit=repo,cli_utils to explicitly target those subsections of the role.
