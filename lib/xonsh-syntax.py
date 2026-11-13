"""Checks the syntax of the xonsh files named on the command line, without
running them. Prints `file:line: problem` for each one that doesn't parse, and
exits 1 if any doesn't. The lint check in ./checks.nix runs it."""
import sys

from xonsh.built_ins import XSH
from xonsh.execer import Execer

execer = Execer()
XSH.load(execer=execer)

broken = 0
for path in sys.argv[1:]:
    with open(path) as file:
        source = file.read()
    try:
        execer.parse(source + "\n", ctx=set(), filename=path)
    except SyntaxError as error:
        print(f"{path}:{error.lineno}: {error.msg}", file=sys.stderr)
        broken += 1

sys.exit(1 if broken else 0)
