# Entrypoint when container is running as a Jenkins agent using the
# Jenkins EC2 plugin. This currently depends on a carefully-crafted AMI
# running a `bootstrap` script located in
# `build-infra/packer/build/couchbase-server/linux/aws`.
#
# THIS IS A FINAL PLUGIN. It will start a long-running SSH daemon, and
# not return control to the entrypoint script.

# Ensure ephemeral-mounted `jenkins` dir is accessible
sudo chown -R couchbase:couchbase /home/couchbase/jenkins

if ! ls /etc/ssh/ssh_host_* &>/dev/null
then
  sudo ssh-keygen -A
fi

# Ensure password auth disabled
if grep -q "^[^#]*PasswordAuthentication" /etc/ssh/sshd_config
then
  sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config
else
  echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config
fi
if grep -q "^[^#]*ChallengeResponseAuthentication" /etc/ssh/sshd_config
then
  sudo sed -i "/^[^#]*ChallengeResponseAuthentication[[:space:]]yes/c\ChallengeResponseAuthentication no" /etc/ssh/sshd_config
else
  echo "ChallengeResponseAuthentication no" | sudo tee -a /etc/ssh/sshd_config
fi

sudo /usr/sbin/sshd -D
