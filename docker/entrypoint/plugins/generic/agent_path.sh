# Sets `agent_path` to a simple default. The contents of /etc/path (if
# any) will be prepended to this default. This is useful for containers
# that run an agent process of some kind.

agent_path=/usr/local/bin:/usr/bin:/bin
if [ -e /etc/path ]; then
    agent_path=$(cat /etc/path):${agent_path}
fi
