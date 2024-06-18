This playbook can be used to (re)create a docker swarm.

It is intended to be used with the inventory file in the parent folder and `--limit`ed to a specific group. Nodes should have a populated manager variable (in the case of managers) and a comma-separated list of `label=value` labels if required.

The first host in the group will be treated as the initial leader and used for swarm init and token retrieval, and delegated to when adding the other nodes.

        [test]
        192.168.5.10 name=node1 manager=true labels=role=build          # <-- leader, manager
        192.168.5.11 name=node2 manager=true labels=role=build          # <-- manager
        192.168.5.12 name=node3 manager=true labels=role=build          # <-- manager
        192.168.5.13 name=node4              labels=role=build          # <-- worker
        192.168.5.14 name=node5              labels=role=build,foo=bar  # <-- worker, multiple roles

It is assumed that all target nodes have docker installed and have a local couchbase user which is a member of the docker group.

Note: "teardown=true" should only be used if your aim is to destroy and recreate an existing swarm.

Example invocation: `ansible-playbook -i ../swarm-inventory playbook.yml --limit server [-e teardown=true]`
