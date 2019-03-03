#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Symling .default-gems..."
ln -sfT ~/.dotfiles/ruby/default-gems ~/.default-gems

echo_done "Ruby configuration!"
