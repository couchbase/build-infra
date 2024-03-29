#!/usr/bin/env bash

# Used to help prompt/trigger an image update to support new distros

docker pull couchbasebuild/sdk-cowbuilder:latest
docker run --rm -i couchbasebuild/sdk-cowbuilder:latest bash -s <<EOF
errors=false
curl -Lfo /tmp/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && chmod 755 /tmp/jq
printf "\n\nChecking contents of /usr/share/debootstrap/scripts\n\n"
for distro in \$(curl -Lf https://raw.githubusercontent.com/couchbase/product-metadata/master/couchbase-server/repo_upload/apt.json  2>/dev/null | /tmp/jq -r '.os_versions | keys | .[]')
do
  if [ ! -f "/usr/share/debootstrap/scripts/\$distro" ]
  then
    echo "/usr/share/debootstrap/scripts/\$distro MISSING"
    errors=true
  else
    echo "/usr/share/debootstrap/scripts/\$distro ok"
  fi
done
[ "$errors" = "true" ] && printf "\n\nFAILED\n" && exit 1
printf "\n\nOK\n"
EOF
