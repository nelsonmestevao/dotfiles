#!/bin/bash

# shellcheck source=distro.sh
. ../distro.sh
# shellcheck source=helpers.sh
. ../helpers.sh

echo_info "Installing Dependencies..."
sudo pacman -S gcc-fortran --need --noconfirm

echo_info "Symlink .Rprofile..."
ln -sfT ~/.dotfiles/R/Rprofile ~/.Rprofile

echo_info "Symlink .Renviron..."
ln -sfT ~/.dotfiles/R/Renviron ~/.Renviron

echo_info "Installing R packages..."
Rscript rpkgs.R

echo_done "R configuration!"
