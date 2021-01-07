#!/bin/bash

sudo su - root

# Download packer
(
    cd /tmp
    curl -LO https://releases.hashicorp.com/packer/1.6.5/packer_1.6.5_linux_amd64.zip
    unzip packer_1.6.5_linux_amd64.zip
    mv packer /usr/local/bin
)

# Install AWS EFS Utilities for mounting EFS volumes
yum install -y amazon-efs-utils python3 python3-pip

# install ansible for running packer - specifically 2.85 because filtering changes in higher versions break some of our playbooks
pip3 install "ansible==2.8.5" pywinrm

mkdir -p /efs/latestbuilds
chown 1000:1000 /efs/latestbuilds

mkdir -p /efs/downloads
chown 1000:1000 /efs/downloads

mkdir -p /efs/nexus
chown 1000:1000 /efs/nexus

mkdir -p /efs/proget
chown 1000:1000 /efs/proget

mkdir -p /efs/jenkins_home/{analytics,cv,server,mobile}
chown 1000:1000 /efs/jenkins_home/{analytics,cv,server,mobile}

echo "mount -t efs -o iam,tls,accesspoint=${analytics_jenkins_accesspoint} ${filesystem}: /efs/jenkins_home/analytics" > /root/mount.sh
echo "mount -t efs -o iam,tls,accesspoint=${cv_jenkins_accesspoint} ${filesystem}: /efs/jenkins_home/cv" >> /root/mount.sh
echo "mount -t efs -o iam,tls,accesspoint=${server_jenkins_accesspoint} ${filesystem}: /efs/jenkins_home/server" >> /root/mount.sh
echo "mount -t efs -o iam,tls,accesspoint=${mobile_jenkins_accesspoint} ${filesystem}: /efs/jenkins_home/mobile" >> /root/mount.sh

echo "mount -t efs -o iam,tls,accesspoint=${latestbuilds_accesspoint} ${filesystem}: /efs/latestbuilds" >> /root/mount.sh
echo "mount -t efs -o iam,tls,accesspoint=${nexus_accesspoint} ${filesystem}: /efs/nexus" >> /root/mount.sh
echo "mount -t efs -o iam,tls,accesspoint=${proget_accesspoint} ${filesystem}: /efs/proget" >> /root/mount.sh
echo "mount -t efs -o iam,tls,accesspoint=${downloads_accesspoint} ${filesystem}: /efs/downloads" >> /root/mount.sh

chmod a+x /root/mount.sh

sleep 120

/root/mount.sh
