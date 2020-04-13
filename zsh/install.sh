#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing ZSH with OH-MY-ZSH..."
_install zsh

echo_info "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo_info "Installing zsh-autosuggestions..."
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

echo_info "Installing Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k

echo_info "Symlink .zshrc..."
ln -sfT "$HOME/.dotfiles/zsh/zshrc" "$HOME/.zshrc"

echo_info "Changing shell..."
chsh -s "$(command -v zsh)"

echo_done "ZSH configuration!"
