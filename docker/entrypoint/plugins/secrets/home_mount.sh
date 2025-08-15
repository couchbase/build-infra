# Copies any files mounted under `/homesecrets` into the couchbase
# user's home directory.
secrets_mount=/homesecrets
if [ -d ${secrets_mount} ] && [ "$(ls -A ${secrets_mount})" ]
then
    status "Copying secrets from ${secrets_mount} to /home/couchbase"
    shopt -s dotglob
    umask 0077
    cp -r ${secrets_mount}/* /home/couchbase
fi
