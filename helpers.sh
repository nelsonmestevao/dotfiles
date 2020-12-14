#!/usr/bin/env bash

. distro.sh

function _update() {
  if [[ "$1" == "system" ]]; then
    echo_info "Updating system packages..."
    sudo "$PKGMN" "$PKGU" "${PKGOPT[@]}"
  else
    echo_info "Updating ${1}..."
    sudo "$PKGMN" "$PKGI" "$1"
  fi
}

function _install() {
  if [[ $1 == "core" ]]; then
    for pkg in "${PKG[@]}"; do
      echo_info "Installing ${pkg}..."
      if ! [ -x "$(command -v rainbow)" ]; then
        sudo "$PKGMN" "$PKGI" "$pkg" "${PKGOPT[@]}"
      else
        rainbow --red=error --yellow=warning sudo "$PKGMN" "$PKGI" "$pkg" "${PKGOPT[@]}"
      fi
      echo_done "${pkg} installed!"
    done
  elif [[ $1 == "aur" ]]; then
    for aur in "${AUR[@]}"; do
      echo_info "Installing ${aur}..."
      yay -Sy "$aur" --needed --noconfirm
      echo_done "${aur} installed!"
    done
  else
    echo_info "Intalling ${1}..."
    sudo "$PKGMN" "$PKGI" "$1" "${PKGOPT[@]}"

    echo_done "${1} installed!"
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

function colorize() {
  local color type=0

  case $1 in
    black)
      color=30
      ;;
    red)
      color=31
      ;;
    green)
      color=32
      ;;
    yellow)
      color=33
      ;;
    blue)
      color=34
      ;;
    magenta)
      color=35
      ;;
    cyan)
      color=36
      ;;
    white)
      color=37
      ;;
    reset | *)
      color=0
      ;;
  esac

  case $2 in
    bold | bright)
      type=1
      ;;
    underline)
      type=4
      ;;
    inverse)
      type=7
      ;;
  esac

  echo -en "\\033[${type};${color}m"
}

function echo_error() {
  colorize red bold
  echo "ERROR:$(colorize reset)" "$@"
}

function echo_warning() {
  colorize yellow bold
  echo "WARNING:$(colorize reset)" "$@"
}

function echo_done() {
  colorize green bold
  echo "DONE:$(colorize reset)" "$@"
}

function echo_info() {
  if [ "$#" -eq 1 ]; then
    PREFIX="INFO"
  else
    PREFIX=$1
    shift 1
  fi

  colorize cyan bold
  echo "${PREFIX}:$(colorize reset)" "$@"
}

function not_installed() {
  [ ! -x "$(command -v "$@")" ]
}

