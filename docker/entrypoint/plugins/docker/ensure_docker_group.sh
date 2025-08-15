# Ensure there's a Unix group for the GID of /var/run/docker.socket, and
# that the couchbase user is in that group.
if [ ! -e /var/run/docker.sock ]; then
    abort "ensure_docker_group: /var/run/docker.sock not found"
fi

sock_gid=$(stat --format=%g /var/run/docker.sock)

# `groupadd --non-unique` is kind of ugly, but we don't have control
# over the GID of the socket from the host, and we don't want to
# fail just because it happens to use the same GID as something in
# the container image
status "Creating group dockercb with GID ${sock_gid}"
sudo groupadd --non-unique --gid ${sock_gid} dockercb
sudo usermod -a -G dockercb couchbase

# Add the dockercb group to the current process. This function does not
# return, so it needs to be the last thing in the plugin.
add_group dockercb
