#!/usr/bin/env bash

set -Eeuo pipefail

import() {
  local -r SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")

  # shellcheck source=/dev/null
  . "${SCRIPTS_DIR}/${1}"
}

# shellcheck source=./helpers.sh
import helpers.sh

function __log() {
  local LABEL="$1"
  local COLOR="$2"
  shift 2
  local MSG=("$@")

  local SIZE
  [[ $(tput cols) -ge 80 ]] && SIZE=80 || SIZE=$(tput cols)

  # Get symbols from https://coolsymbol.com/
  printf "_${COLOR}${BOLD}${LABEL}${RESET}_╞%*s\n" $((SIZE - ${#LABEL} - 3)) " " | sed -e 's/ /═/g' | sed -e 's/_/ /g'
  for M in "${MSG[@]}"; do
    echo "• $M"
  done
  printf "%*s\n" "$SIZE" " " | sed -e 's/ /═/g'
}

function log_error() {
  __log "FAIL" "$RED" "$@"
}

function log_warn() {
  __log "WARN" "$ORANGE" "$@"
}

function log_success() {
  __log "OK" "$GREEN" "$@"
}

function log_info() {
  local LABEL="INFO"

  if ! [ "$#" -eq 1 ]; then
    LABEL=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    shift 1
  fi

  __log "${LABEL}" "$CYAN" "$@"
}

[ "$0" = "${BASH_SOURCE[0]}" ] && display_version 0.7.0 || true
