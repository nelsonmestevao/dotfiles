#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing LaTeX..."
_install texlive-most

echo_info "Symlink ~/.latexmkrc"
ln -sfT ~/.dotfiles/latex/latexmkrc ~/.latexmkrc

echo_done "LaTeX configuration!"
