#!/bin/bash

# Xcode-Install Wrapper
#
# Does the homebrew/ruby/gem dance to install xcode-install,
# then invokes it.
# Note: On some Macs, "brew install" will first have to update Homebrew,
# which can take quite a while and sometimes fails. Re-running usually
# then succeeds.
# Note: while xcode-install seems to manage avoiding ever popping up
# dialogs, it may sometimes need a sudo password, so it's not 100%
# automatable.

export PATH=~/.gem/2.6.0/bin:/usr/local/opt/ruby/bin:$PATH

install_xcversion() {
    ruby_ver=$(ruby -e 'RUBY_VERSION')
    if [[ $ruby_ver =~ ^2\.[012345].* ]]; then
        brew install ruby
        hash -r
    fi

    # Use this recipe just in case the machine doesn't have a compiler already
    curl -sL -O https://github.com/neonichu/ruby-domain_name/releases/download/v0.5.99999999/domain_name-0.5.99999999.gem
    gem install domain_name-0.5.99999999.gem
    gem install --conservative xcode-install
    rm -f domain_name-0.5.99999999.gem
}

if ! type -P xcversion > /dev/null; then
    install_xcversion
fi

if [ -e ~/.ssh/appleid.txt ]; then
    export XCODE_INSTALL_USER=$(cat ~/.ssh/appleid.txt)
fi
if [ -e ~/.ssh/appleid.password ]; then
    export XCODE_INSTALL_PASSWORD=$(cat ~/.ssh/appleid.password)
fi

xcversion "$@"
