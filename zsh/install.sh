#!/usr/bin/env sh

echo "Installing ZSH with OH-MY-ZSH..."
sudo pacman -Syu zsh --needed --noconfirm

# oh-my-zsh installation
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

git clone https://github.com/zsh-users/zsh-autosuggestions         "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

ln -sfT "$HOME/.dotfiles/zsh/zshrc"   "$HOME/.zshrc"

chsh -s "$(command -v zsh)"

