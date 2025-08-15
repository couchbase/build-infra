# Sync secrets from the in-datacenter profiledata service. Requires the
# following env vars to be set to determine the profile to load:
#
#   NODE_CLASS   (e.g. build, cv)
#   NODE_PRODUCT (e.g. couchbase-server)
#
# Also requires the following file to exist (presumably as a Docker secret):
#
#   /run/secrets/profiledata_ssh_key

chk_set NODE_CLASS NODE_PRODUCT
chk_file /run/secrets/profiledata_ssh_key
chk_cmd ssh-keyscan ssh rsync

profile_port="4000"
profile_host="profiledata.build.couchbase.com"

# Ensure profiledata is in known_hosts
mkdir -p /home/couchbase/.ssh
touch /home/couchbase/.ssh/known_hosts
hostkeys="$(ssh-keyscan -p ${profile_port} ${profile_host})"
for key in "$hostkeys"
do
    if ! grep "$key" /home/couchbase/.ssh/known_hosts &>/dev/null && :
    then
        echo "$key" >> /home/couchbase/.ssh/known_hosts
    fi
done

status "Populating profile data"

for node_class in ${NODE_CLASS}; do
    rsync --progress --archive --backup --executability --no-o --no-g \
        -e "ssh -p ${profile_port} -i /run/secrets/profiledata_ssh_key -o StrictHostKeyChecking=no" \
        couchbase@${profile_host}:${NODE_PRODUCT}/${node_class}/linux/ /home/couchbase/
done
