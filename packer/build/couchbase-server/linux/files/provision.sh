# Wait for any ongoing yum stuff to happen before we start installing things
while ps -ef | grep 'yum' | grep -v 'grep'
do
     sleep 5
done

sudo yum install -y \
    aws-cli \
    bc \
    docker \
    ec2-instance-connect \
    jq \
    lvm2 \
    nano \
    python3 \
    python3-pip

# start_worker needs to parse our yaml stackfiles
sudo pip3 install pyyaml

# Enable IPv6 in docker daemon
sudo mkdir -p /etc/docker
cat << EOF | sudo tee /etc/docker/daemon.json
{
    "ipv6": true,
    "fixed-cidr-v6": "fde1:ebe3:498b:5707::/64"
}
EOF


sudo mv /tmp/bootstrap /usr/bin
sudo chmod a+x /usr/bin/bootstrap

sudo mkdir /opt/buildteam

echo "${REGION}" | sudo tee /opt/buildteam/region
echo "region: $(</opt/buildteam/region)"
