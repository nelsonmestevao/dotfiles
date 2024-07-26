#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/distro.sh
. scripts/distro.sh
# shellcheck source=../scripts/execs.sh
. scripts/execs.sh
# shellcheck source=../scripts/utils.sh
. scripts/utils.sh

#ask_for_sudo

#install_package zsh

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

git clone https://github.com/hlissner/zsh-autopair $ZSH_CUSTOM/plugins/zsh-autopair

git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM/plugins/fzf-tab

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

ln -s "$HOME/.dotfiles/zsh/zshrc" "$HOME/.zshrc"

