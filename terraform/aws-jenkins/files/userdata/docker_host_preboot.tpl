#!/bin/bash
cloud-init-per once prereqs yum install libguestfs-tools iptables-services -y

cloud-init-per once disk1 pvcreate /dev/nvme2n1 /dev/nvme3n1
cloud-init-per once disk2 vgcreate nvme /dev/nvme1n1 /dev/nvme2n1
cloud-init-per once disk3 lvcreate --name docker --size 550GB nvme
cloud-init-per once disk4 mkfs.ext4 /dev/nvme/docker
cloud-init-per once disk9 rm -rf /var/lib/docker
cloud-init-per once disk5 mkdir -p /var/lib/docker
cloud-init-per once disk7 echo "/dev/nvme/docker /var/lib/docker ext4 defaults,nofail,discard 0 2" >> /etc/fstab
cloud-init-per once disk8 mount -a

cloud-init-per once ecs1 echo ECS_CLUSTER=${ecs_cluster} > /etc/ecs/ecs.config
cloud-init-per once ecs2 echo ECS_AWSVPC_BLOCK_IMDS=true >> /etc/ecs/ecs.config
