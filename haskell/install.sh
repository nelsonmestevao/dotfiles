#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Symling .ghci..."
ln -sfT ~/.dotfiles/haskell/ghci ~/.ghci

echo_done "Haskell configuration!"
