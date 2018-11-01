#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing Mercurial..."
_install mercurial

echo_info "Symlink ~/.hgrc"
ln -sfT ~/.dotfiles/hg/hgrc ~/.hgrc

echo_done "Mercurial configuration!"
