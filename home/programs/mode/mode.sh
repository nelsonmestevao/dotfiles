#!/usr/bin/env bash

# Switch the screen set-up: chill for working alone, demo for showing your screen.

set -Eeuo pipefail
shopt -s inherit_errexit

PROGRAM=$(basename "${BASH_SOURCE[0]:-$0}")
VERSION=0.7.0

# help_section <title>: print the title of a help section in bold capitals.
function help_section() {
  printf '\033[1m%s\033[0m' "${*^^}"
}

: "${DOTFILES:?must point to the dotfiles checkout}"
readonly CODE_SETTINGS="${DOTFILES}/home/programs/vscode/settings.json"
readonly ZED_SETTINGS="${DOTFILES}/home/programs/zed/settings.json"
readonly GHOSTTY_CONFIG="${DOTFILES}/home/programs/ghostty/config"

# The settings a mode controls, in the order change_to applies them. Each
# has a get_<name> and set_<name> function, and each MODES entry lists one
# value per setting, in this same order.
declare -ra SETTINGS=(theme caffeine notifications opacity editor_font_size terminal_font_size)
declare -rA MODES=(
  [chill]="dark   off  on   0.6  18  16"
  [demo]="light  on   off  1    32  26"
)

# Settings this system cannot switch. change_to leaves them as they are, and
# status shows "-" for them. macOS has no command for Do Not Disturb.
declare -a UNSUPPORTED=()
if [[ ${OSTYPE} == darwin* ]]; then
  UNSUPPORTED=(notifications)
fi
readonly UNSUPPORTED

# is_supported SETTING
function is_supported() {
  declare -r setting="$1"
  declare unsupported

  for unsupported in "${UNSUPPORTED[@]}"; do
    [ "${unsupported}" != "${setting}" ] || return 1
  done
}

function die() {
  echo "${PROGRAM}: $*" >&2
  exit 1
}

# With set -E this fires inside functions and $(...) too, so an unexpected
# failure (a missing theme, caffeine or notifications, a sed error, ...) names the command
# and the line instead of exiting silently. A failure inside $(...) is
# reported there, and die() prints its own message before exiting, so the
# assignment that receives either one stays quiet instead of repeating it.
function on_error() {
  declare -r status="$1"
  declare -r line="$2"
  declare -r command="$3"

  if [[ ${command} == *=\$\(* ]]; then
    return
  fi

  echo "${PROGRAM}: line ${line}: '${command}' failed with exit status ${status}" >&2
}
trap 'on_error "$?" "${LINENO}" "${BASH_COMMAND}"' ERR

# require_single_line FILE PREFIX
#
# Fail unless exactly one line of FILE contains PREFIX, taken literally, so
# a renamed or duplicated key is reported instead of being silently skipped
# or clobbered.
function require_single_line() {
  declare -r file="$1"
  declare -r prefix="$2"
  declare matches

  [ -f "${file}" ] || die "${file}: no such file"

  matches=$(grep -cF -- "${prefix}" "${file}" || true)
  [ "${matches}" -eq 1 ] || die "${file}: expected exactly one line containing '${prefix}', found ${matches}"
}

# read_line FILE PREFIX
#
# Print what follows PREFIX on the single line of FILE that contains it,
# without a trailing comma.
function read_line() {
  declare -r file="$1"
  declare -r prefix="$2"
  declare line

  require_single_line "${file}" "${prefix}"

  line=$(grep -F -- "${prefix}" "${file}")
  line="${line#*"${prefix}"}"
  echo "${line%,}"
}

# replace_line FILE PREFIX REST
#
# On the single line of FILE that contains PREFIX, keep PREFIX and replace
# everything after it with REST. Both are taken literally.
function replace_line() {
  declare -r file="$1"
  declare -r prefix="$2"
  declare -r rest="$3"
  declare escaped_prefix escaped_rest

  require_single_line "${file}" "${prefix}"

  escaped_prefix=$(printf '%s\n' "${prefix}" | sed 's/[][\.*^$/]/\\&/g')
  escaped_rest=$(printf '%s\n' "${rest}" | sed 's/[\/&]/\\&/g')

  sed -i -e "s/\(${escaped_prefix}\).*/\1${escaped_rest}/" "${file}"
}

function display_help() {
  cat << EOF
  $(help_section Usage)
    ${PROGRAM} [options] (<screen> | status)

  $(help_section Screens)
    chill           Notifications on, caffeine off, default font-size and dark mode
    demo            Notifications off, caffeine on, big font-size and light mode

  $(help_section Commands)
    status          Show the current mode and the values behind it

  $(help_section Options)
    -h, --help      Show this screen.
    -v, --version   Show version.
    -t, --theme     Show current theme.
    -k, --keyboard  Turn the keyboard light on or off.
EOF
}

# keyboard_light [PERCENT]
#
# Print the keyboard light's brightness as a percentage, after setting it to
# PERCENT when one is given. The Framework keyboard is a QMK device, so this
# goes through qmk_hid. qmk_hid exits with 0 even when it finds no keyboard,
# so its output is checked instead.
function keyboard_light() {
  declare output

  output=$(qmk_hid via --backlight ${1:+"$1"} 2>&1) || true
  if [[ ${output} =~ ^Brightness:\ ([0-9]+)%$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ ${output} == *"Permission denied"* ]]; then
    die "no permission to reach the keyboard; it needs a udev rule that gives you its hidraw device"
  else
    die "cannot reach the keyboard light: ${output%%$'\n'*}"
  fi
}

# Turn the keyboard light off if it is on, or to full brightness if it is off.
function toggle_keyboard_light() {
  declare level

  level=$(keyboard_light)
  if [ "${level}" -eq 0 ]; then
    level=$(keyboard_light 100)
  else
    level=$(keyboard_light 0)
  fi

  echo "Keyboard light at ${level}%"
}

function get_notifications() {
  notifications status
}

function set_notifications() {
  notifications "$1"
}

function get_editor_font_size() {
  read_line "${CODE_SETTINGS}" '"editor.fontSize": '
}

function set_editor_font_size() {
  declare -r size="$1"

  replace_line "${CODE_SETTINGS}" '"editor.fontSize": ' "${size},"
  replace_line "${ZED_SETTINGS}" '"buffer_font_size": ' "${size},"
}

function get_opacity() {
  read_line "${GHOSTTY_CONFIG}" 'background-opacity = '
}

function set_opacity() {
  declare -r opacity="$1"

  replace_line "${GHOSTTY_CONFIG}" 'background-opacity = ' "${opacity}"
}

function get_terminal_font_size() {
  read_line "${GHOSTTY_CONFIG}" 'font-size = '
}

function set_terminal_font_size() {
  declare -r size="$1"

  replace_line "${GHOSTTY_CONFIG}" 'font-size = ' "${size}"
  replace_line "${CODE_SETTINGS}" '"terminal.integrated.fontSize": ' "${size},"
  # Only the terminal block has a bare "font_size" key; ui_font_size and
  # buffer_font_size do not match because of the leading quote, and
  # replace_line fails if that ever stops being true.
  replace_line "${ZED_SETTINGS}" '"font_size": ' "${size},"
}

function get_theme() {
  theme status
}

function set_theme() {
  theme "$1"
}

function get_caffeine() {
  caffeine status
}

function set_caffeine() {
  caffeine "$1"
}

function change_to() {
  declare -r mode="$1"
  declare -a values
  declare i

  read -ra values <<< "${MODES[${mode}]}"
  [ "${#values[@]}" -eq "${#SETTINGS[@]}" ] || die "mode ${mode} has ${#values[@]} values, expected one per setting (${#SETTINGS[@]})"

  for i in "${!SETTINGS[@]}"; do
    if ! is_supported "${SETTINGS[i]}"; then
      echo "▲ ${SETTINGS[i]}: not on macOS, left as they are" >&2
      continue
    fi
    "set_${SETTINGS[i]}" "${values[i]}"
  done

  echo "Changed to mode ${mode}!"
}

# current_mode ACTUAL
#
# Print the name of the mode whose settings equal ACTUAL (the fields of a
# MODES entry separated by single spaces), or "custom" when none matches.
function current_mode() {
  declare -r actual="$1"
  declare name fields i

  for name in "${!MODES[@]}"; do
    read -ra fields <<< "${MODES[${name}]}"
    # A setting this system cannot switch cannot tell two modes apart.
    for i in "${!SETTINGS[@]}"; do
      is_supported "${SETTINGS[i]}" || fields[i]="-"
    done
    if [ "${fields[*]}" = "${actual}" ]; then
      echo "${name}"
      return
    fi
  done

  echo custom
}

function display_status() {
  declare -a values=()
  declare setting value i

  for setting in "${SETTINGS[@]}"; do
    if is_supported "${setting}"; then
      value=$("get_${setting}")
    else
      value="-"
    fi
    values+=("${value}")
  done

  current_mode "${values[*]}"
  for i in "${!SETTINGS[@]}"; do
    printf '  %-20s%s\n' "${SETTINGS[i]//_/ }" "${values[i]}"
  done
}

case ${1:-error} in
  -h | --help)
    display_help
    ;;
  -v | --version)
    echo "${PROGRAM} v${VERSION}"
    ;;
  -t | --theme)
    theme status
    ;;
  -k | --keyboard)
    toggle_keyboard_light
    ;;
  status)
    display_status
    ;;
  chill | demo)
    change_to "$1"
    ;;
  *)
    display_help >&2
    exit 1
    ;;
esac
