if [ -z ${KEYCHAIN_PASSWORD+x} ]; then
    echo "KEYCHAIN_PASSWORD is unset in calling environment, required to install brew"
    exit 1
fi
set -e
# brew will run some sudo commands, this gives it permission to do so
echo $KEYCHAIN_PASSWORD | sudo -S 'ls'
chmod 700 askpass.sh
export SUDO_ASKPASS=$(pwd)/askpass.sh
# unattended installation mode for brew
CI=1 /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
ls -l /usr/local/bin/brew # ensure this worked or generate nonzero exit code
