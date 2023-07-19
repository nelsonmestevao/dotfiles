#!/usr/bin/env bash

set -Eeuo pipefail

import() {
  local -r SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

  # shellcheck source=/dev/null
  . "${SCRIPTS_DIR}/${1}"
}

# shellcheck source=./colors.sh
import colors.sh
# shellcheck source=./helpers.sh
import helpers.sh

declare -A LOG_LEVELS
LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=3 [ERROR]=4)

# Set default log level
LOG_LEVEL=${LOG_LEVEL:-"DEBUG"}

function exit_message() {
  echo -e "\n ${RED}>>>${RESET} ${BOLD}${YELLOW}$1${RESET} ${RED}⨯${RESET}\n"
}

function __log() {
  local LEVEL="$1"
  local LABEL="$2"
  local COLOR="$3"
  shift 3
  local MSG=("$@")

  if [ "${LOG_LEVELS[$LEVEL]}" -ge "${LOG_LEVELS[$LOG_LEVEL]}" ]; then
    local SIZE
    [[ $(tput cols) -ge 80 ]] && SIZE=80 || SIZE=$(tput cols)

    # Get symbols from https://coolsymbol.com/
    printf "_${COLOR}${BOLD}${LABEL}${RESET}_╞%*s\n" $((SIZE - ${#LABEL} - 3)) " " | sed -e 's/ /═/g' | sed -e 's/_/ /g'
    for M in "${MSG[@]}"; do
      echo "• $M"
    done
    printf "%*s\n" "$SIZE" " " | sed -e 's/ /═/g'
  fi
}

function log_error() {
  __log "ERROR" "FAIL" "$RED" "$@"
}

function log_warn() {
  __log "WARN" "WARN" "$YELLOW" "$@"
}

function log_success() {
  __log "INFO" "OK" "$GREEN" "$@"
}

function log_info() {
  local LABEL="INFO"
  local MSGS=()

  while (($#)); do
    case "$1" in
      --label)
        LABEL=$(echo "$2" | tr '[:lower:]' '[:upper:]')
        shift 2
        ;;
      --) # end argument parsing
        shift
        break
        ;;
      -*) # unsupported flags
        exit_message "Unsupported flag '$1' in 'log_info()' function"
        exit 1
        ;;
      *) # preserve positional arguments
        MSGS+=("$1")
        shift
        ;;
    esac
  done

  __log "INFO" "$LABEL" "$BLUE" "${MSGS[@]}"
}

function log_debug() {
  __log "DEBUG" "DEBUG" "$PURPLE" "$@"
}

([ "$0" = "${BASH_SOURCE[0]}" ] && display_version 0.14.0) || true
