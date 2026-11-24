#!/usr/bin/env xonsh
"""
Keep the screen from sleeping or locking.

On GNOME this switches the Caffeine extension. On macOS it runs the built-in
caffeinate in the background until you turn it off.

Usage:
  {program} [on | off | status]
  {program} (-h | --help)
  {program} --version

Options:
  -h --help              Show this screen.
  -v --version           Show version.

Needs from your system:
  GNOME with the Caffeine extension (gsettings), or macOS (caffeinate).
"""

from subprocess import DEVNULL, Popen

import os
import signal
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from spellbook import ask, parse_args, success


MACOS = sys.platform == "darwin"

# macOS: where this spell notes the process id of the caffeinate it started.
# Other apps run caffeinate too, so "is any caffeinate running" says nothing.
PID_FILE = os.path.join(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")), "caffeine.pid")

def gsettings_get_caffeine_status():
    return $(gsettings get org.gnome.shell.extensions.caffeine cli-toggle).strip().lower()

def macos_caffeinate_pid():
    """The process id of the caffeinate this spell started, or None when it is not running."""
    try:
        with open(PID_FILE) as f:
            pid = int(f.read())
    except (OSError, ValueError):
        return None

    # The note can outlive the process, after a reboot for example. Check
    # that the process is still there and still is caffeinate.
    command = !(ps -p @(pid) -o command=).out
    return pid if "caffeinate" in command else None

def macos_set_caffeine(status):
    pid = macos_caffeinate_pid()

    if status == "on" and pid is None:
        # -d keeps the display on, -i keeps the Mac from sleeping when idle.
        # A session of its own lets caffeinate live on after this spell ends.
        caffeinate = Popen(["caffeinate", "-d", "-i"], start_new_session=True, stdin=DEVNULL, stdout=DEVNULL, stderr=DEVNULL)
        os.makedirs(os.path.dirname(PID_FILE), exist_ok=True)
        with open(PID_FILE, "w") as f:
            f.write(str(caffeinate.pid))
    elif status == "off" and pid is not None:
        os.kill(pid, signal.SIGTERM)
        os.remove(PID_FILE)

def get_caffeine_status():
    if MACOS:
        return "off" if macos_caffeinate_pid() is None else "on"

    match gsettings_get_caffeine_status():
        case "true":
            return "on"
        case "false":
            return "off"

def set_caffeine(status):
    if MACOS:
        macos_set_caffeine(status)
    else:
        match status:
            case "on":
                gsettings set org.gnome.shell.extensions.caffeine cli-toggle true
            case "off":
                gsettings set org.gnome.shell.extensions.caffeine cli-toggle false

    success(f"caffeine is {status}")

def main(args):
    if args["on"]:
        set_caffeine("on")
    elif args["off"]:
        set_caffeine("off")
    elif args["status"]:
        print(get_caffeine_status())
    else:
        status = ask("choose", "on", "off")
        set_caffeine(status)

if __name__ == "__main__":
    main(parse_args(__doc__, __file__, version="0.2.0"))

# vim: ft=xonsh
