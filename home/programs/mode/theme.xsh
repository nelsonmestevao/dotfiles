#!/usr/bin/env xonsh
"""
Switch the desktop between dark and light. Apps that follow the desktop change with it.

Usage:
  {program} [dark | light | status]
  {program} (-h | --help)
  {program} --version

Options:
  -h --help              Show this screen.
  -v --version           Show version.

Needs from your system:
  GNOME (gsettings), or macOS (osascript and defaults).
"""

import os
import sys

# The package puts spellbook.xsh, from scripts/ in the repo, next to this file.
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from spellbook import ask, parse_args, success


MACOS = sys.platform == "darwin"

def gsettings_get_color_scheme():
    return $(gsettings get org.gnome.desktop.interface color-scheme).strip().lower()

def macos_is_dark():
    # The setting holds "Dark" in dark mode. In light mode it does not exist and
    # `defaults` fails. That is an answer, not an error, so `!()` and not `$()`.
    return !(defaults read -g AppleInterfaceStyle).out.strip() == "Dark"

def get_current_theme():
    if MACOS:
        return "dark" if macos_is_dark() else "light"

    match gsettings_get_color_scheme():
        case "'prefer-dark'":
            return "dark"
        case "'default'":
            return "light"
        case _:
            return "¯\\_(ツ)_/¯"

def set_theme_to(theme):
    if MACOS:
        # The first time, macOS asks whether this terminal may control System Events.
        dark_mode = "true" if theme == "dark" else "false"
        osascript -e @(f'tell application "System Events" to tell appearance preferences to set dark mode to {dark_mode}')
    else:
        color_scheme = "prefer-dark" if theme == "dark" else "default"
        gsettings set org.gnome.desktop.interface color-scheme @(color_scheme)

    success(f"{theme} mode activated")

def main(args):
    if args["dark"]:
        set_theme_to("dark")
    elif args["light"]:
        set_theme_to("light")
    elif args["status"]:
        print(get_current_theme())
    else:
        theme = ask("choose", "dark", "light")
        set_theme_to(theme)

if __name__ == "__main__":
    main(parse_args(__doc__, __file__, version="0.2.0"))

# vim: ft=python
