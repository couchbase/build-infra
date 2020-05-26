Setup Server MACOS

Prereq
1. IP address of a running macOS target (this playbook has been tested with Mojave but should also work on Catalina)

Deploy tools via ansible
1. git clone https://github.com/couchbase/build-infra.git
2. cd build-infra/ansible/macosx/couchbase-server
3. Run the playbook specifying password where required

    `$ ansible-playbook -i inventory playbook.yml -e "ansible_ssh_pass=<jenkins_pass>" -e XCODE_INSTALL_USER=<apple account> -e XCODE_INSTALL_PASSWORD=<apple account> -e XCODE_VERSION=<version> --ask-become-pass`

Note: Tagging is used at role and block level to ease debugging. For instance use --limit=software to limit your run to performing all the tasks in the software role, or you could use --limit=repo,cli_utils to explicitly target those subsections of the role.