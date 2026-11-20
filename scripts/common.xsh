"""What the xonsh helpers in bin/ share: where they run, what a failure looks
like, and colours that only show in a terminal.

A helper imports this before anything else:

    sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "scripts"))
    from common import fail, paint, run, GREEN

and ends with `run(main, __doc__, __file__)`. Importing it also turns on
flakes for every nix and nh call the helper makes.
"""
import getpass
import json
import os
import subprocess
import sys

from docopt import docopt

# Every helper runs from the repo root, wherever it was called from.
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# A failed command stops the helper. xonsh does that by default today; saying
# so keeps it true if the default changes. `run` below turns the error into one
# plain line, so the traceback is hidden. Commands captured with !() don't
# stop the helper; those check their own return code.
$XONSH_SUBPROC_RAISE_ERROR = True
$XONSH_SHOW_TRACEBACK = False

# Without a terminal Python holds its output back, and the commands' output
# would overtake it. Writing each line at once keeps a log in order.
sys.stdout.reconfigure(line_buffering=True)

RED, GREEN, YELLOW, BLUE, CYAN, GREY = 31, 32, 33, 34, 36, 90


def paint(text, color, stream=sys.stdout):
    """`text` in `color` when `stream` is a terminal, plain when it's a file
    or a pipe. Each stream decides for itself, so `2> err.log` stays clean."""
    return f"\033[1;{color}m{text}\033[0m" if stream.isatty() else text


def error(message):
    """Says what went wrong, in one line, and goes on."""
    print(f"{paint('✗', RED, sys.stderr)} {message}", file=sys.stderr)


def fail(message):
    """Says what went wrong, in one line, and stops with exit status 1."""
    error(message)
    sys.exit(1)


def warn(message):
    print(f"{paint('!', YELLOW, sys.stderr)} {message}", file=sys.stderr)


# Flakes for every nix and nh call, keeping what NIX_CONFIG already holds,
# like an access token. Nix skips the blank first line when it held nothing.
$NIX_CONFIG = ${...}.get('NIX_CONFIG', '') + '\nextra-experimental-features = nix-command flakes'


def failed(problem):
    """One line for what stopped a step: the command and that it failed, or
    "Interrupted" for Ctrl-C. xonsh raises CalledProcessError for every
    failed command, even one missing from PATH."""
    if isinstance(problem, KeyboardInterrupt):
        return "Interrupted"
    return f"{' '.join(map(str, problem.cmd))} failed"


def targets(only=None):
    """This machine's configs, read from config/hosts.nix: its system, when it
    has one, and the home of whoever runs the helper. `only` is "os" or
    "home" to pick one. Each config is (its name, the nh command for it, the
    nh flags that pick it). Stops with one plain line when there is nothing
    to pick."""
    hosts = json.loads($(nix eval --json --file config/hosts.nix))
    host = $(hostname -s).strip()
    if host not in hosts:
        fail(f"config/hosts.nix has no host named {host}. It has {', '.join(sorted(hosts))}.")
    platform = hosts[host].get('platform')
    user = getpass.getuser()
    found = []
    if only != 'home':
        if platform:
            kind = {'nixos': 'os', 'darwin': 'darwin'}[platform]
            found.append((f"{platform}Configurations.{host}", kind, ['-H', host]))
        elif only == 'os':
            fail(f"{host} has no system config, only a home.")
    if only != 'os':
        if user not in hosts[host].get('users', []):
            hint = " Pass os for the system only." if platform and only is None else ""
            fail(f"{host} has no home for {user}. config/hosts.nix lists its users.{hint}")
        found.append((f"{user}@{host}", 'home', ['-c', f"{user}@{host}"]))
    return found


def run(main, doc, file):
    """Reads the arguments with docopt and calls `main` with them. A command
    that fails, or Ctrl-C, ends the helper with one plain line. So does a
    mistake the helper found itself (a ValueError, like a bad name) and a file
    it could not read or write."""
    arguments = docopt(doc.format(program=file), version=f'{os.path.basename(file)} script version 1.0')
    try:
        main(arguments)
    except (subprocess.CalledProcessError, KeyboardInterrupt) as problem:
        fail(f"{failed(problem)}.")
    except (ValueError, OSError) as problem:
        fail(str(problem))

# vim: ft=xonsh
