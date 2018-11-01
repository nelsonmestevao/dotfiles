#!/bin/bash

function echo_error() {
  printf "\\n\\033[31mERROR:\\033[0m %s\\n" "$1"
}

function echo_warning() {
  printf "\\n\\033[33mWARNING:\\033[0m %s\\n" "$1"
}

function echo_done() {
  printf "\\n\\033[32mDONE:\\033[0m %s\\n" "$1"
}

function echo_info() {
  printf "\\n\\033[36m%s\\033[0m\\n" "$1"
}

function _update() {
  if [[ "$1" != "system" ]]; then
    echo_info "Updating system packages..."
    sudo "$PKGMN" "$PKGU" "${PKGOPT[@]}"
  else
    echo_info "Updating ${1}..."
    sudo "$PKGMN" "$PKGI" "$1"
  fi
}

function _install() {
  if [[ "$1" == "core" ]]; then
    for pkg in "${PKG[@]}"; do
      echo_info "Installing ${pkg}..."
      if ! [ -x "$(command -v rainbow)" ]; then
        sudo "$PKGMN" "$PKGI" "$pkg" "${PKGOPT[@]}"
      else
        rainbow --red=error --yellow=warning sudo "$PKGMN" "$PKGI" "$pkg" "${PKGOPT[@]}"
      fi
      echo_done "${pkg} installed!"
    done
  elif [[ "$1" == "aur" ]]; then
    for aur in "${AUR[@]}"; do
      echo_info "Installing ${aur}..."
      yaourt -Sy "$aur" --needed --noconfirm
      echo_done "${aur} installed!"
    done
  else
    echo_info "Intalling ${1}..."
    sudo "PKGMN" "$PKGI" "$1"
  fi
}

function _symlink() {
  dirs=$(find . -maxdepth 1 -mindepth 1 -type d -not -name '.git' -print)

  for dir in $dirs; do
    echo "Installing ${dir}..."
    cd "$dir" || exit
    ./install.sh
    cd ..
  done
}
