#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing haskell..."
_install stack
_install ghc
_install ghc-libs
_install ghc-static

echo_info "Symling .ghci..."
ln -sfT ~/.dotfiles/haskell/ghci ~/.ghci

echo_done "Haskell configuration!"
