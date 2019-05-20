#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Symling .ideavimrc..."
ln -sfT ~/.dotfiles/IdeaVim/ideavimrc ~/.ideavimrc
echo_done "IdeaVim configuration!"
