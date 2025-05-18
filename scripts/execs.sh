#!/usr/bin/env bash

set -Eeuo pipefail

import() {
  local -r SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]:-$0}")

  # shellcheck source=/dev/null
  . "${SCRIPTS_DIR}/${1}"
}

# shellcheck source=./helpers.sh
import helpers.sh

__set_trap() {
  trap -p "$1" | grep "$2" &>/dev/null ||
    trap '$2' "$1"
}

__kill_all_subprocesses() {
  local i=""

  for i in $(jobs -p); do
    kill "$i"
    wait "$i" &>/dev/null
  done
}

__print_error_stream() {
  while read -r line; do
    echo -e "    ↳ ${RED}ERROR${RESET}: $line"
  done
}

__print_result() {
  if [ "$1" -eq 0 ]; then
    echo -e " • $2 ${GREEN}✓${RESET}"
  else
    echo -e " • $2 ${RED}⨯${RESET}"
  fi

  return "$1"
}

# Ideas from https://github.com/alrra/dotfiles/blob/main/src/os/utils.sh
__show_spinner() {
  #local -r FRAMES='/-\|'
  local -r FRAMES='⡿⣟⣯⣷⣾⣽⣻⢿'

  # shellcheck disable=SC2034
  local -r NUMBER_OR_FRAMES=${#FRAMES}

  local -r CMDS="$2"
  local -r MSG="$3"
  local -r PID="$1"

  local i=0
  local frameText=""

  # Note: In order for the Travis CI site to display
  # things correctly, it needs special treatment, hence,
  # the "is Travis CI?" checks.
  if [ "${CI:-false}" != "true" ]; then
    # Provide more space so that the text hopefully
    # doesn't reach the bottom line of the terminal window.
    #
    # This is a workaround for escape sequences not tracking
    # the buffer position (accounting for scrolling).
    #
    # See also: https://unix.stackexchange.com/a/278888
    printf "\n\n\n"
    tput cuu 3
    tput sc
  fi

  # Display spinner while the commands are being executed.
  while kill -0 "$PID" &>/dev/null; do
    frameText=" • $MSG ${FRAMES:i++%NUMBER_OR_FRAMES:1}"

    # Print frame text.
    if [ "${CI:-false}" != "true" ]; then
      printf "%s\n" "$frameText"
    else
      printf "%s" "$frameText"
    fi

    sleep 0.2

    # Clear frame text.
    if [ "${CI:-false}" != "true" ]; then
      tput rc
    else
      printf "\r"
    fi
  done
}

function execute() {
  local -r CMDS="$1"
  local -r MSG="${2:-$1}"
  local -r TMP_FILE="$(mktemp /tmp/XXXXX)"

  local exitCode=0
  local cmdsPID=""

  # If the current process is ended, also end all its subprocesses.
  __set_trap "EXIT" "__kill_all_subprocesses"

  # Execute commands in background
  eval "$CMDS" &>"$TMP_FILE" &

  cmdsPID=$!

  # Show a spinner if the commands require more time to complete.
  __show_spinner "$cmdsPID" "$CMDS" "$MSG"

  # Wait for the commands to no longer be executing
  # in the background, and then get their exit code.
  wait "$cmdsPID" &>/dev/null
  exitCode=$?

  # Print output based on what happened.
  __print_result $exitCode "$MSG"

  if [ $exitCode -ne 0 ]; then
    __print_error_stream <"$TMP_FILE"
  fi

  rm -rf "$TMP_FILE"

  return $exitCode
}

([ "$0" = "${BASH_SOURCE[0]}" ] && display_version 0.16.0) || true
