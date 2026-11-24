#!/usr/bin/env xonsh
"""
Open a Herdr space on a git worktree for a branch, creating the worktree if needed.

If a worktree already has <branch>, it uses that folder. If not, it adds one in
~/.herdr/worktrees/<project>/<name>, where <name> is the branch with each "/"
turned into "-". The branch comes from the first of: a local branch,
<remote>/<branch>, or a new branch made from the remote's default branch.

Then it switches to the Herdr space open on that folder, or makes a new one
called <name>. With no <branch>, it fetches and lets you pick one from a list.

On a machine with hc but no herdr-app (a server), it makes the space with hc.
The space shows up in the Herdr sidebar, but the window won't switch to it.

When a branch is done and its worktree is removed (git clean-branches does
that), the space stays open on a folder that is gone. --prune closes every
such space on this computer.

Usage:
  {program} [<branch>] [options]
  {program} --prune [--dry-run]
  {program} (-h | --help)
  {program} --version

Options:
  -h --help              Show this screen.
  -v --version           Show version.
  -r --remote=<remote>   Remote to look for branches in [default: origin].
  -s --setup=<cmd>       Run <cmd> in a new tab of the space (stays open after).
  --prune                Close every Herdr space whose folder is gone.
  -n --dry-run           With --prune: only list the spaces it would close.

Needs from your system:
  git, and herdr-app or hc.
"""

import json
import os
import shutil
import sys
import uuid

# The package puts spellbook.xsh, from scripts/ in the repo, next to this file.
sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))
from spellbook import error, log_info, parse_args, pick, step, success


WORKTREES = os.path.expanduser("~/.herdr/worktrees")


def execute(title, argv):
    """Run argv behind a spinner; on failure, show its output and stop."""
    if not step(title, argv):
        sys.exit(1)


def git(*args):
    """Run git quietly and return (ok, stdout)."""
    p = !(git @(args))
    return p.returncode == 0, p.output.strip()

def has_ref(ref):
    return git("show-ref", "--verify", "--quiet", ref)[0]

def worktrees():
    """(path, branch) for each worktree, main one first. branch is None when detached."""
    entries = []
    for block in git("worktree", "list", "--porcelain")[1].split("\n\n"):
        path = branch = None
        for line in block.splitlines():
            if line.startswith("worktree "):
                path = line.removeprefix("worktree ")
            elif line.startswith("branch refs/heads/"):
                branch = line.removeprefix("branch refs/heads/")
        if path:
            entries.append((path, branch))
    return entries

def fetch(remote):
    if ![gum spin --align=right --title @(f"Fetching {remote}...") -- git fetch --quiet @(remote)]:
        success(f"Fetched {remote}")
    else:
        error(f"Could not fetch {remote}")

def default_base(remote):
    """Where a new branch starts: the remote's default branch, as <remote>/<name>."""
    ok, ref = git("symbolic-ref", "--short", f"refs/remotes/{remote}/HEAD")
    if ok:
        return ref
    for name in ("main", "master"):
        if has_ref(f"refs/remotes/{remote}/{name}"):
            return f"{remote}/{name}"
    error(f"Could not find the default branch of {remote}")

def pick_branch(remote):
    """Let the person pick a local or remote branch."""
    out = git("for-each-ref", "--format=%(refname)", "refs/heads", f"refs/remotes/{remote}")[1]
    names = []
    for ref in out.splitlines():
        if ref == f"refs/remotes/{remote}/HEAD":
            continue
        name = ref.removeprefix("refs/heads/").removeprefix(f"refs/remotes/{remote}/")
        if name not in names:
            names.append(name)
    return pick(names, "Pick a branch...")

def add_worktree(branch, path, remote, fetched):
    """Add a worktree for branch at path from a local, remote or new branch."""
    if has_ref(f"refs/heads/{branch}"):
        execute(f"Adding worktree for {branch}", ["git", "worktree", "add", path, branch])
        return

    if not fetched:
        fetch(remote)

    if has_ref(f"refs/remotes/{remote}/{branch}"):
        execute(f"Adding worktree for {remote}/{branch}",
                ["git", "worktree", "add", "--track", "-b", branch, path, f"{remote}/{branch}"])
    else:
        base = default_base(remote)
        execute(f"Adding worktree for new branch {branch} from {base}",
                ["git", "worktree", "add", "--no-track", "-b", branch, path, base])


def herdr_spaces():
    p = !(herdr-app ls)
    if p.returncode != 0:
        error(f"Herdr is not running: {(p.errors or '').strip()}")
    return json.loads(p.output)["spaces"]

def inside(folder, path):
    """True when folder is path or a folder inside it."""
    if not folder:
        return False
    folder, path = os.path.realpath(folder), os.path.realpath(path)
    return folder == path or folder.startswith(path + os.sep)

def space_on(spaces, path):
    """The first space whose folder is path or inside it."""
    return next((space for space in spaces if inside(space.get("folder"), path)), None)

def herdr_do(*args):
    p = !(herdr-app do @(args))
    if p.returncode != 0:
        error(f"herdr-app do {args[0]} failed: {p.output.strip()} {(p.errors or '').strip()}")
    # A command with nothing to report may print nothing.
    return json.loads(p.output) if p.output.strip() else {}

def open_space(name, path, spaces):
    """Show the space on path, making it if needed. Returns its id."""
    space = space_on(spaces, path)
    if space:
        herdr_do("space.select", "--id", space["id"])
        success(f"Switched to space {space['name']}")
        return space["id"]
    space_id = herdr_do("space.new", "--name", name, "--folder", path)["space"]
    success(f"Opened space {name}")
    return space_id

def stale_spaces(spaces):
    """The spaces on this computer whose folder is gone.

    A space on another machine has its folder there, where this computer
    cannot look. A space with no folder starts in the home folder.
    """
    return [space for space in spaces
            if not space.get("machine") and space.get("folder") and not os.path.isdir(space["folder"])]

def prune(dry_run):
    """Close every space whose folder is gone, or only list them."""
    if not shutil.which("herdr-app"):
        error("herd --prune needs herdr-app on PATH")

    stale = stale_spaces(herdr_spaces())
    if not stale:
        log_info("Every space has its folder. Nothing to close.")
        return

    for space in stale:
        where = f"{space['name']} ({space['folder']})"
        if dry_run:
            log_info(f"Would close space {where}")
        else:
            # Herdr asks before it closes a space, unless told it was confirmed.
            herdr_do("space.close", json.dumps({"id": space["id"], "confirmed": True}))
            success(f"Closed space {where}")

def hc_space_on(path):
    """(space id, place) of a live Herdr terminal in path, or (None, None)."""
    p = !(hc ls --json)
    if p.returncode != 0:
        error(f"hc ls failed: {(p.errors or '').strip()}")
    for terminal in json.loads(p.output)["terminals"]:
        if not inside(terminal.get("cwd"), path):
            continue
        got = !(hc get @(terminal["address"]))
        if got.returncode != 0:
            continue
        space_id = json.loads(got.output).get("labels", {}).get("herdr.space")
        if space_id:
            return space_id, terminal.get("where", space_id)
    return None, None

def open_space_hc(path):
    """Find or make the space on path with hc alone. Returns its id.

    Without herdr-app nothing can switch the window to the space. But a shell
    labeled with a space id Herdr doesn't know becomes a new space, named
    after its folder.
    """
    space_id, where = hc_space_on(path)
    if space_id:
        success(f"Already open in space {where}")
        return space_id
    space_id = f"sp{uuid.uuid4().hex}"
    p = !(hc run --bg --no-parent --keep --cwd @(path) --label @(f"herdr.space={space_id}"))
    if p.returncode != 0:
        error(f"Could not start a shell for the space: {(p.errors or '').strip()}")
    success(f"Opened space {os.path.basename(path)}; find it in the Herdr sidebar")
    return space_id

def run_setup(cmd, path, space_id):
    """Run cmd in its own tab of the space, then leave a shell there."""
    p = !(hc run --bg --no-parent --cwd @(path) --label @(f"herdr.space={space_id}") @(f'{cmd}; exec "${{SHELL:-sh}}"'))
    if p.returncode != 0:
        error(f"Could not start setup: {(p.errors or '').strip()}")
    success(f"Started setup: {cmd}")


def main(args):
    remote = args["--remote"]
    branch = args["<branch>"]

    if args["--prune"]:
        prune(args["--dry-run"])
        return

    if not git("rev-parse", "--git-dir")[0]:
        error("Not inside a git repo")

    # herdr-app only exists where the Herdr window runs. A server has just hc.
    app = shutil.which("herdr-app") is not None
    if not app and not shutil.which("hc"):
        error("herd needs herdr-app or hc on PATH")
    spaces = herdr_spaces() if app else None

    fetched = False
    if not branch:
        fetch(remote)
        fetched = True
        branch = pick_branch(remote)
        if not branch:
            sys.exit(1)

    trees = worktrees()
    project = os.path.basename(trees[0][0])
    name = branch.replace("/", "-")
    path = next((p for p, b in trees if b == branch), None)

    if path and not os.path.isdir(path):
        error(f"{branch} is checked out in {path}, but that folder is gone. Run: git worktree prune")

    if path:
        log_info(f"{branch} is already checked out in {path}")
    else:
        path = os.path.join(WORKTREES, project, name)
        if os.path.exists(path):
            error(f"{path} already exists but is not a worktree for {branch}")
        add_worktree(branch, path, remote, fetched)

    space_id = open_space(name, path, spaces) if app else open_space_hc(path)

    if args["--setup"]:
        run_setup(args["--setup"], path, space_id)


if __name__ == "__main__":
    main(parse_args(__doc__, __file__, version="0.2.0"))

# vim: ft=python
