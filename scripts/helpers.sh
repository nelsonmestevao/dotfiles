#!/usr/bin/env bash

set -Eeuo pipefail

import() {
  local -r SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")

  # shellcheck source=/dev/null
  . "${SCRIPTS_DIR}/${1}"
}

# shellcheck source=./colors.sh
import colors.sh

function display_version() {
  local program="${2:-$(basename "$0")}"
  local version=${1:?"You need to give a version number"}

  if [ -x "$(command -v figlet)" ]; then
    echo -n "${BLUE}${BOLD}"
    figlet "${program} script"
    echo -n "${RESET}"
    echo "version ${version}"
  else
    echo "${program} script version ${version}"
  fi
}

function help_title_section() {
  local -r TITLE=$(echo "$@" | tr '[:lower:]' '[:upper:]')
  echo -e "${BOLD}${TITLE}${RESET}"
}

([ "$0" = "${BASH_SOURCE[0]}" ] && display_version 0.15.0) || true
