#!/bin/bash -e

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd ${SCRIPTPATH}

set +x
source ~/.ssh/notarizer_env
security unlock-keychain -p `cat ~/.ssh/security-password.txt` ${HOME}/Library/Keychains/login.keychain
export AUTH_TOKEN="$(cat ~/.ssh/notarizer_token 2>/dev/null)"

set -x
/usr/local/bin/node index.js
