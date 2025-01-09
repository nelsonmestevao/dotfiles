#!/usr/bin/env bash

set -Eeuo pipefail

import() {
  local -r SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")

  # shellcheck source=/dev/null
  . "${SCRIPTS_DIR}/${1}"
}

# shellcheck source=./helpers.sh
import helpers.sh

__ansi() {
  echo -e "\e[${1}m${*:2}\e[0m"
}

function bold() {
  __ansi 1 "$@"
}

function italic() {
  __ansi 3 "$@"
}

function underline() {
  __ansi 4 "$@"
}

function strikethrough() {
  __ansi 9 "$@"
}

function format() {
  local COLOR=0 TYPE=0
  local TEXT=()

  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      -c | --color)
        case ${2:-reset} in
          black)
            COLOR=30
            ;;
          red)
            COLOR=31
            ;;
          green)
            COLOR=32
            ;;
          yellow)
            COLOR=33
            ;;
          blue)
            COLOR=34
            ;;
          magenta)
            COLOR=35
            ;;
          cyan)
            COLOR=36
            ;;
          white)
            COLOR=37
            ;;
          reset)
            COLOR=0
            ;;
        esac
        shift 2
        ;;
      -t | --type)
        case ${2:-reset} in
          bold | bright)
            TYPE=1
            ;;
          fade)
            TYPE=2
            ;;
          italic)
            TYPE=3
            ;;
          underline)
            TYPE=4
            ;;
          blink)
            TYPE=5
            ;;
          inverse)
            TYPE=7
            ;;
          strikethrough)
            TYPE=9
            ;;
          reset)
            TYPE=0
            ;;
        esac
        shift 2
        ;;
      *)
        TEXT+=("$1")
        shift
        ;;
    esac
  done

  if ((COLOR > 0)); then
    echo -en "\\033[${TYPE:-0};${COLOR:-0}m"
  else
    echo -en "\\033[0;${TYPE:-0}m"
  fi

  if [[ ${#TEXT[@]} -gt 1 ]]; then
    for text in "${TEXT[@]}"; do
      echo "$text"
    done

    echo -en '\033[0;0m'
  elif [[ ${#TEXT[@]} -eq 1 ]]; then
    for text in "${TEXT[@]}"; do
      echo -n "$text"
    done

    echo -en '\033[0;0m'
  fi
}

([ "$0" = "${BASH_SOURCE[0]}" ] && display_version 0.15.0) || true
