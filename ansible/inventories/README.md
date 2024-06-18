This directory contains subdirectories of Ansible inventories that are
not specifically associated with any particular playbook or role
(although there may be one here for convenience/testing). They simply
capture certain interesting sets of hosts inside our datacenter.

In particular, docker-swarms contains a single inventory with sections
for all of our Docker Swarm instances, including metadata such as role
labels. This could be used (with scripts in docker-swarms/swarm-build)
to recreate a swarm on top of new VMs.
