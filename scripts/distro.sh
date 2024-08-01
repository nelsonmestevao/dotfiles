#!/usr/bin/env bash

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

function is_installed() {
  [ -x "$(command -v "$@")" ]
}

function install_package() {
  local PKG="$1"

  if is_installed apt; then
    execute "sudo apt -y ${PKG}" "Installing ${BOLD}${PKG}${RESET}..."
  elif is_installed dnf; then
    execute "sudo dnf install -y ${PKG}" "Installing ${BOLD}${PKG}${RESET}..."
  elif is_installed yay; then
    execute "yay -Syyu ${PKG} --needed --noconfirm" "Installing ${BOLD}${PKG}${RESET}..."
  elif is_installed pacman; then
    execute "sudo pacman -Syyu ${PKG} --needed --noconfirm" "Installing ${BOLD}${PKG}${RESET}..."
  elif is_installed brew; then
    execute "brew install -y ${PKG}" "Installing ${BOLD}${PKG}${RESET}..."
  fi
}
