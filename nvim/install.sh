#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installling Neovim..."
_install neovim

_install python2-neovim
_install python-neovim

if [[ -x "$(command -v yaourt)" ]]; then
  yaourt -Sy ruby-neovim --needed --noconfirm
  yaourt -Sy nodejs-neovim --needed --noconfirm
fi

echo_info "Installing vim-plug..."
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo_info "Symling init.vim..."
mkdir -p ~/.config/nvim
ln -sfT ~/.dotfiles/nvim/init.vim ~/.config/nvim/init.vim

echo_done "Neovim configuration!"
