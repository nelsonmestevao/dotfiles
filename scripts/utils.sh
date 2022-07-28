#!/usr/bin/env bash

set -Eeuo pipefail

import() {
  local -r SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")

  # shellcheck source=/dev/null
  . "${SCRIPTS_DIR}/${1}"
}

# shellcheck source=./helpers.sh
import helpers.sh

function not_installed() {
  [ ! -x "$(command -v "$@")" ]
}

function load_env_file() {
  local file="${1:-.env}"
  if [ -f "$file" ]; then
    log_info "Environment" "Loading ${BLUE}${file}${RESET}..." "$(cat "${file}")"
    set -o allexport
    # shellcheck source=/dev/null
    source "$file"
    set +o allexport
  else
    log_warn "${file} file not found, skipping..."
  fi
}

function ask_for_sudo() {
  # Ask for the administrator password upfront.
  sudo -v &>/dev/null

  # Update existing `sudo` time stamp
  # until this script has finished.
  #
  # https://gist.github.com/cowboy/3118588
  while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done &>/dev/null &
}

function ensure_confirmation() {
  read -r "confirmation?please confirm you want to continue [y/n] (default: y) "
  confirmation=${confirmation:-"y"}

  if [ "$confirmation" != "y" ]; then
    exit 1
  fi
}

function get_os_name() {
  uname | tr '[:upper:]' '[:lower:]'
}

[ "$0" = "${BASH_SOURCE[0]}" ] && display_version 0.7.0 || true
