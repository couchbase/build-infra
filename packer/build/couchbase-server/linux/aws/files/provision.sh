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
    nvme-cli \
    python3 \
    python3-pip

# start_worker needs to parse our yaml stackfiles
sudo pip3 install pyyaml

# yq for parsing stackfiles to discover image names
arch=$(uname -m)
case $arch in
x86_64)
  arch=amd64
  ;;
aarch64)
  arch=arm64
  ;;
esac
sudo curl -fLo /usr/bin/yq "https://github.com/mikefarah/yq/releases/download/v4.12.0/yq_linux_${arch}"
sudo chmod a+x /usr/bin/yq

# Enable IPv6 in docker daemon
sudo mkdir -p /etc/docker
cat << EOF | sudo tee /etc/docker/daemon.json
{
    "ipv6": true,
    "fixed-cidr-v6": "fde1:ebe3:498b:5707::/64"
}
EOF

sudo mkdir -p /opt/buildteam/hooks

sudo mv /tmp/bootstrap /usr/bin
sudo chmod a+x /usr/bin/bootstrap

sudo mv /tmp/cv-hook.sh /opt/buildteam/hooks

sudo chmod a+x /opt/buildteam/hooks/*

echo "${REGION}" | sudo tee /opt/buildteam/region
echo "region: $(</opt/buildteam/region)"
