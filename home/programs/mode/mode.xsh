#!/usr/bin/env xonsh
"""
Switch the screen set-up: chill for working alone, demo for showing your screen.

Usage:
  {program} (chill | demo | status)
  {program} (-t | --theme)
  {program} (-k | --keyboard)
  {program} (-h | --help)
  {program} --version

Screens:
  chill                  Notifications on, caffeine off, default font size and dark mode.
  demo                   Notifications off, caffeine on, big font size and light mode.

Commands:
  status                 Show the current mode and the values behind it.

Options:
  -h --help              Show this screen.
  -v --version           Show version.
  -t --theme             Show the current theme.
  -k --keyboard          Turn the keyboard light on or off.

Needs from your system:
  $DOTFILES set to the dotfiles checkout, whose editor and terminal settings
  it edits.
"""

from pathlib import Path
from subprocess import PIPE, STDOUT, run

import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from spellbook import error, log_warn, parse_args, success


MACOS = sys.platform == "darwin"

# The settings each mode sets, in the order change_to applies them. Each one
# has a get_<name> and a set_<name> function.
MODES = {
    "chill": {
        "theme": "dark",
        "caffeine": "off",
        "notifications": "on",
        "opacity": "0.6",
        "editor_font_size": "18",
        "terminal_font_size": "16",
    },
    "demo": {
        "theme": "light",
        "caffeine": "on",
        "notifications": "off",
        "opacity": "1",
        "editor_font_size": "32",
        "terminal_font_size": "26",
    },
}

# Settings this system cannot switch. change_to leaves them as they are, and
# status shows "-" for them. macOS has no command for Do Not Disturb.
UNSUPPORTED = {"notifications"} if MACOS else set()


# --- Files in the checkout ---------------------------------------------------

def checkout_file(path):
    dotfiles = os.environ.get("DOTFILES")
    if not dotfiles:
        error("DOTFILES: must point to the dotfiles checkout")
    return Path(dotfiles) / path

def code_settings():
    return checkout_file("home/programs/vscode/settings.json")

def zed_settings():
    return checkout_file("home/programs/zed/settings.json")

def ghostty_config():
    return checkout_file("home/programs/ghostty/config")

def single_line(file, prefix):
    """
    The lines of file, and the index of the one line that contains prefix.

    It fails unless exactly one line has it, so a renamed or repeated key is
    reported instead of skipped or changed twice.
    """
    if not file.is_file():
        error(f"{file}: no such file")
    lines = file.read_text().splitlines(keepends=True)
    matches = [i for i, line in enumerate(lines) if prefix in line]
    if len(matches) != 1:
        error(f"{file}: expected exactly one line containing '{prefix}', found {len(matches)}")
    return lines, matches[0]

def read_line(file, prefix):
    """What follows prefix on its line of file, without a trailing comma."""
    lines, i = single_line(file, prefix)
    return lines[i].rstrip("\n").split(prefix, 1)[1].removesuffix(",")

def replace_line(file, prefix, rest):
    """On the line of file that contains prefix, keep prefix and put rest after it."""
    lines, i = single_line(file, prefix)
    line = lines[i]
    newline = line[len(line.rstrip("\n")):]
    lines[i] = line.split(prefix, 1)[0] + prefix + rest + newline
    # write_text and not a new file: the checkout's files may be links.
    file.write_text("".join(lines))


# --- The other commands of this package --------------------------------------

def command_output(*argv):
    result = !(@(argv))
    if not result:
        error(f"{' '.join(argv)} failed")
    return result.out.strip()

def command(*argv):
    if not ![@(argv)]:
        error(f"{' '.join(argv)} failed")


# --- Settings ----------------------------------------------------------------

def get_theme():
    return command_output("theme", "status")

def set_theme(value):
    command("theme", value)

def get_caffeine():
    return command_output("caffeine", "status")

def set_caffeine(value):
    command("caffeine", value)

def get_notifications():
    return command_output("notifications", "status")

def set_notifications(value):
    command("notifications", value)

def get_opacity():
    return read_line(ghostty_config(), "background-opacity = ")

def set_opacity(value):
    replace_line(ghostty_config(), "background-opacity = ", value)

def get_editor_font_size():
    return read_line(code_settings(), '"editor.fontSize": ')

def set_editor_font_size(value):
    replace_line(code_settings(), '"editor.fontSize": ', f"{value},")
    replace_line(zed_settings(), '"buffer_font_size": ', f"{value},")

def get_terminal_font_size():
    return read_line(ghostty_config(), "font-size = ")

def set_terminal_font_size(value):
    replace_line(ghostty_config(), "font-size = ", value)
    replace_line(code_settings(), '"terminal.integrated.fontSize": ', f"{value},")
    # Only the terminal block has a bare "font_size" key. ui_font_size and
    # buffer_font_size don't match because of the leading quote, and
    # replace_line fails if that ever stops being true.
    replace_line(zed_settings(), '"font_size": ', f"{value},")

SETTERS = {
    "theme": set_theme,
    "caffeine": set_caffeine,
    "notifications": set_notifications,
    "opacity": set_opacity,
    "editor_font_size": set_editor_font_size,
    "terminal_font_size": set_terminal_font_size,
}

GETTERS = {
    "theme": get_theme,
    "caffeine": get_caffeine,
    "notifications": get_notifications,
    "opacity": get_opacity,
    "editor_font_size": get_editor_font_size,
    "terminal_font_size": get_terminal_font_size,
}


# --- Modes -------------------------------------------------------------------

def change_to(mode):
    for setting, value in MODES[mode].items():
        if setting in UNSUPPORTED:
            log_warn(f"{setting}: not on macOS, left as they are")
            continue
        SETTERS[setting](value)

    success(f"Changed to mode {mode}!")

def current_values():
    return {
        setting: "-" if setting in UNSUPPORTED else get()
        for setting, get in GETTERS.items()
    }

def current_mode(values):
    """The name of the mode whose settings are values, or "custom"."""
    for name, settings in MODES.items():
        # A setting this system cannot switch cannot tell two modes apart.
        wanted = {s: "-" if s in UNSUPPORTED else v for s, v in settings.items()}
        if wanted == values:
            return name
    return "custom"

def display_status():
    values = current_values()
    print(current_mode(values))
    for setting, value in values.items():
        print(f"  {setting.replace('_', ' '):<20}{value}")


# --- The keyboard light ------------------------------------------------------

def keyboard_light(percent=None):
    """
    The keyboard light's brightness in percent, after setting it to percent
    when one is given.

    The Framework keyboard is a QMK device, so this goes through qmk_hid.
    qmk_hid exits with 0 even when it finds no keyboard, so its output is
    checked instead.
    """
    argv = ["qmk_hid", "via", "--backlight"] + ([str(percent)] if percent is not None else [])
    try:
        output = run(argv, stdout=PIPE, stderr=STDOUT, text=True).stdout.strip()
    except FileNotFoundError:
        error("cannot reach the keyboard light: qmk_hid is not installed")

    if level := re.fullmatch(r"Brightness: (\d+)%", output):
        return int(level[1])
    if "Permission denied" in output:
        error("no permission to reach the keyboard; it needs a udev rule that gives you its hidraw device")
    error(f"cannot reach the keyboard light: {output.splitlines()[0] if output else 'no answer'}")

def toggle_keyboard_light():
    level = keyboard_light(100 if keyboard_light() == 0 else 0)
    print(f"Keyboard light at {level}%")


def main(args):
    if args["--theme"]:
        print(get_theme())
    elif args["--keyboard"]:
        toggle_keyboard_light()
    elif args["status"]:
        display_status()
    elif args["chill"]:
        change_to("chill")
    elif args["demo"]:
        change_to("demo")

if __name__ == "__main__":
    main(parse_args(__doc__, __file__, version="0.8.0"))

# vim: ft=xonsh
