"""What the xonsh helpers in bin/ share: where they run, what a failure looks
like, and colours that only show in a terminal.

A helper imports this before anything else:

    sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "scripts"))
    from common import fail, paint, run, with_flakes, GREEN

and ends with `run(main, __doc__, __file__)`.
"""
import os
import subprocess
import sys

from docopt import docopt
from xonsh.tools import XonshError

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

RED, GREEN, YELLOW = 31, 32, 33


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


def with_flakes():
    """Turns on flakes for the nix and nh calls that follow, keeping whatever
    NIX_CONFIG already holds, like an access token."""
    before = ${...}.get('NIX_CONFIG', '')
    $NIX_CONFIG = (before + '\n' if before else '') + 'extra-experimental-features = nix-command flakes'


# What a failed command can raise: a non-zero exit, or a command xonsh
# couldn't start, like one missing from PATH.
COMMAND_ERRORS = (subprocess.CalledProcessError, XonshError)


def failed(problem):
    """One line for what stopped a step: the command and that it failed, or
    "Interrupted" for Ctrl-C."""
    if isinstance(problem, KeyboardInterrupt) or interrupted(problem):
        return "Interrupted"
    if isinstance(problem, subprocess.CalledProcessError):
        return f"{' '.join(map(str, problem.cmd))} failed"
    return str(problem).strip().splitlines()[0]


def interrupted(problem):
    """True when a command ended because of Ctrl-C (exit status 130, or
    killed by a signal), so it isn't taken for an ordinary failure."""
    code = getattr(problem, 'returncode', 0)
    return code == 130 or code < 0


def run(main, doc, file):
    """Reads the arguments with docopt and calls `main` with them. A command
    that fails, or Ctrl-C, ends the helper with one plain line."""
    arguments = docopt(doc.format(program=file), version=f'{os.path.basename(file)} script version 1.0')
    try:
        main(arguments)
    except (*COMMAND_ERRORS, KeyboardInterrupt) as problem:
        fail(f"{failed(problem)}.")

# vim: ft=xonsh
