#!/bin/sh

apt install zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

ln -sfT ~/.dotfiles/zsh/zshrc ~/.zshrc

chsh -s `which zsh`
