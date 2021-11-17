#!/bin/bash -e

# Seed "variables" used by scripts

mkdir -p /opt/build-team/vars
echo "${backup_device}" > /opt/build-team/vars/backup_device
echo "${data_device}" > /opt/build-team/vars/data_device
echo "${scratch_device}" > /opt/build-team/vars/scratch_device
echo "${volumes}" > /opt/build-team/vars/volumes
echo "${web_port}" > /opt/build-team/vars/web_port
echo "${git_port}" > /opt/build-team/vars/git_port
echo "${redirect_port}" > /opt/build-team/vars/redirect_port
echo "${backup_bucket}" > /opt/build-team/vars/backup_bucket
echo "${vol_list}" > /opt/build-team/vars/vol_list
echo "${vol_mount_args}" > /opt/build-team/vars/vol_mount_args
echo "${region}" > /opt/build-team/vars/region
echo "${sns_arn}" > /opt/build-team/vars/sns_arn
echo "${volume}" > /opt/build-team/vars/volume
echo "${url}" > /opt/build-team/vars/url
echo "${data_volume_throughput}" > /opt/build-team/vars/data_volume_throughput
echo "${backup_restore_volume_iops}" > /opt/build-team/vars/backup_restore_volume_iops
echo "${backup_restore_volume_throughput}" > /opt/build-team/vars/backup_restore_volume_throughput


###################
# Install prereqs #
###################

yum install -y \
    docker \
    git \
    iptables-services \
    jq

# Need aws cli 2 to set throughput on new volumes
pushd /tmp
rm -f awscliv2.zip || true
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
rm -f awscliv2.zip
popd


################################
# Populate scripts and configs #
################################

pushd /tmp
git clone https://github.com/couchbase/build-infra
cd build-infra
cp -a terraform/gerrit/files/configs /opt/build-team
cp -a terraform/gerrit/files/static /opt/build-team
cp -a terraform/gerrit/files/scripts/* /usr/bin
chmod a+x /usr/bin/gerrit-*
popd


###################################
# Set up EBS volumes/mount points #
###################################

gerrit-attach-data-volume
mkdir -p /mnt/{data,backup,scratch}
echo "/dev/${data_device} /mnt/data ext4 defaults,nofail,discard 0 2" >> /etc/fstab
echo "/dev/${backup_device} /mnt/backup ext4 defaults,nofail,noatime,discard 0 2" >> /etc/fstab
echo "/dev/${scratch_device} /mnt/scratch ext4 defaults,nofail,noatime,discard 0 2" >> /etc/fstab

mount /mnt/data || (
    # Initialise if/when first mount fails
    sudo mkfs -t ext4 /dev/${data_device}
    mount /mnt/data
)


############################
# Add user to docker group #
############################

usermod -aG docker ec2-user


####################
# Retrieve secrets #
####################

gerrit-get-secrets


##############################################
# Drop container access to instance metadata #
##############################################

cat << 'EOF' > /etc/sysconfig/iptables
*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -d 169.254.169.254/32 -j DROP
COMMIT
EOF


#####################
# Configure logging #
#####################

cat << 'EOF' > /etc/docker/daemon.json
{
  "log-driver": "awslogs",
  "log-opts": {
    "awslogs-region": "${region}",
    "awslogs-group" : "gerrit"
  }
}
EOF


##################
# Start services #
##################

systemctl enable iptables && systemctl start iptables
systemctl enable docker && systemctl start docker
gerrit-start
