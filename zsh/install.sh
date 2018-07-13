#!/bin/bash

echo "Installing ZSH with OH-MY-ZSH..."
sudo apt-get install zsh -yqq

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

ln -sfT ~/.dotfiles/zsh/zshrc ~/.zshrc

chsh -s "$(which zsh)"
