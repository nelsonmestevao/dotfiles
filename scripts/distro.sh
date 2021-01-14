#!/usr/bin/env bash
# DOTFILES EXTRA's

function log_section() {
  local LABEL="$1"
  local COLOR="$PURPLE"
  printf "[${COLOR}${BOLD}${LABEL}${RESET}]%*s\n" $(($(tput cols) - ${#LABEL} - 2)) | sed -e 's/ /═/g'
}

function symlink() {
  local SRC="$1"
  local DST="$2"

  execute "ln -sfT ${SRC} ${DST}" "Symlinking $(basename $DST)"
}

function install_package() {
  local PKG="$1"

  execute "yay -Syyu ${PKG} --needed --noconfirm" "Installing ${BOLD}${PKG}${RESET}..."
}
