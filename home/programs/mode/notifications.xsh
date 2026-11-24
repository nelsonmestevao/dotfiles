#!/usr/bin/env xonsh
"""
Toggle desktop notification banners.

Usage:
  {program} [on | off | status]
  {program} (-h | --help)
  {program} --version

Options:
  -h --help              Show this screen.
  -v --version           Show version.

Needs from your system:
  gsettings (GNOME). macOS has no command for Do Not Disturb, so on a Mac
  this spell only says that it cannot switch them.
"""

import os
import sys

# The package puts spellbook.xsh, from scripts/ in the repo, next to this file.
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from spellbook import ask, error, parse_args, success


MACOS = sys.platform == "darwin"


def gsettings_get_show_banners():
    return $(gsettings get org.gnome.desktop.notifications show-banners).strip().lower()

def get_notifications_status():
    match gsettings_get_show_banners():
        case "true":
            return "on"
        case "false":
            return "off"
        case other:
            return other

def set_notifications(status):
    match status:
        case "on":
            gsettings set org.gnome.desktop.notifications show-banners true
        case "off":
            gsettings set org.gnome.desktop.notifications show-banners false

    success(f"notifications are {status}")

def main(args):
    if MACOS:
        # macOS has no command for Do Not Disturb. The only supported way is
        # a shortcut made by hand in the Shortcuts app.
        error("notifications cannot be switched on macOS")

    if args["on"]:
        set_notifications("on")
    elif args["off"]:
        set_notifications("off")
    elif args["status"]:
        print(get_notifications_status())
    else:
        set_notifications(ask("choose", "on", "off"))


if __name__ == "__main__":
    main(parse_args(__doc__, __file__, version="0.2.0"))

# vim: ft=python
