#!/usr/bin/env bash

BASE_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")
cd "${BASE_DIR}/.." || exit 127

# shellcheck source=../scripts/extras.sh
. scripts/extras.sh

install_package gcc-fortran

install_package rstudio-desktop

symlink ~/.dotfiles/R/Rprofile ~/.Rprofile

symlink ~/.dotfiles/R/Renviron ~/.Renviron

execute "Rscript rpkgs.R" "Installing R packages..."
