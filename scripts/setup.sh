#!/usr/bin/env bash

git clone git@github.com:nelsonmestevao/dotfiles.git ~/.dotfiles
git clone git@github.com:nelsonmestevao/spells.git ~/.spells

cd ~/.dotfiles
make install
