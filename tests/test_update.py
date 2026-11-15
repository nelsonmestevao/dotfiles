"""Run with: bin/test.

bin/update in a throwaway repo. A stand-in nix answers `nix flake update` by
swapping in another flake.lock, so nothing is fetched. The tests check what
bin/update makes of the two lock files: the summary it prints, and the commit
--save writes.
"""
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]

# Logs each call. `nix flake update` copies $AFTER over flake.lock, or fails
# like a broken download when $AFTER is empty.
NIX = '''#!/bin/sh
echo "$*" >> "$LOG"
[ "$1 $2" = "flake update" ] || exit 2
[ -n "$AFTER" ] || { echo "error: unable to download" >&2; exit 1; }
cp "$AFTER" flake.lock
'''

# `gum spin <flags> -- <command>` runs the command, with no spinner.
GUM = '''#!/bin/sh
while [ "$#" -gt 0 ] && [ "$1" != "--" ]; do shift; done
shift
exec "$@"
'''

# Real revisions, from the commit that upgraded claude-code and nixpkgs.
CLAUDE_OLD = '376fb1856b0aa2d4f233b303ba84194592bcd304'
CLAUDE_NEW = '2c0782ecf4d07e4395cb56b33555fa4eb30f6784'
NIXPKGS_OLD = 'ac588ef1c914865dad517b337ea0eb9694a4021c'
NIXPKGS_NEW = 'f1e5c356f35d07e7b71a6b5e6c9338e0b029e0c0'


def rev(digit):
    """A made-up revision: one hex digit 40 times."""
    return digit * 40


def day(date):
    """`lastModified` for noon UTC on `date`."""
    return int(datetime.fromisoformat(f'{date}T12:00:00+00:00').timestamp())


def github(owner, repo, revision, date):
    return {'type': 'github', 'owner': owner, 'repo': repo, 'rev': revision,
            'lastModified': day(date), 'narHash': f'sha256-{revision[:8]}'}


def flake(inputs):
    """A flake.lock. `inputs` maps each input's path ("vicinae" or
    "vicinae/numen") to its locked attributes, or to a list: the path of the
    input it follows. A parent comes before its own inputs."""
    nodes = {'root': {'inputs': {}}}
    for path, value in inputs.items():
        parent, _, name = path.rpartition('/')
        follows = isinstance(value, list)
        nodes[parent or 'root'].setdefault('inputs', {})[name] = value if follows else path
        if not follows:
            original = {k: v for k, v in value.items() if k in ('type', 'owner', 'repo', 'url')}
            nodes[path] = {'locked': value, 'original': original}
    return {'nodes': nodes, 'root': 'root', 'version': 7}


HOME_MANAGER = github('nix-community', 'home-manager', rev('e'), '2026-11-01')

# Before and after an update that moves claude-code and nixpkgs. home-manager
# stays put, and its nixpkgs follows ours, so neither is listed.
BEFORE = flake({
    'claude-code': github('sadjow', 'claude-code-nix', CLAUDE_OLD, '2026-11-12'),
    'home-manager': HOME_MANAGER,
    'home-manager/nixpkgs': ['nixpkgs'],
    'nixpkgs': github('NixOS', 'nixpkgs', NIXPKGS_OLD, '2026-11-08'),
})
AFTER = flake({
    'claude-code': github('sadjow', 'claude-code-nix', CLAUDE_NEW, '2026-11-13'),
    'home-manager': HOME_MANAGER,
    'home-manager/nixpkgs': ['nixpkgs'],
    'nixpkgs': github('NixOS', 'nixpkgs', NIXPKGS_NEW, '2026-11-13'),
})


class UpdateTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='update test ')
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        self.repo = self.dir / 'repo'
        for name in ('bin/update', 'scripts/common.xsh'):
            (self.repo / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(ROOT / name, self.repo / name)
        stubs = self.dir / 'stub'
        stubs.mkdir()
        for name, body in (('nix', NIX), ('gum', GUM)):
            (stubs / name).write_text(body)
            (stubs / name).chmod(0o755)
        self.log = self.dir / 'nix.log'
        # Git ignores my own config here, so a commit is never signed.
        self.env = dict(os.environ, PATH=f'{stubs}{os.pathsep}{os.environ["PATH"]}',
                        LOG=str(self.log), AFTER='', GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1',
                        GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.com',
                        GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.com')
        self.env.pop('NIX_CONFIG', None)
        self.git('init', '-q')

    def git(self, *args):
        result = subprocess.run(['git', *args], cwd=self.repo, env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def update(self, before, after, *args, success=True):
        """Commits `before` as flake.lock, then runs bin/update, where `nix
        flake update` writes `after`. With `after` None, nix fails."""
        (self.repo / 'flake.lock').write_text(json.dumps(before, indent=2) + '\n')
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'start')
        env = dict(self.env)
        if after is not None:
            path = self.dir / 'after.lock'
            path.write_text(json.dumps(after, indent=2) + '\n')
            env['AFTER'] = str(path)
        result = subprocess.run([shutil.which('xonsh'), '--no-rc', 'bin/update', *args], cwd=self.repo, env=env,
                                stdin=subprocess.DEVNULL, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        self.assertNotIn('Traceback', result.stdout + result.stderr)
        # Neither stream is a terminal here, so neither gets color codes.
        self.assertNotIn('\033', result.stdout + result.stderr)
        return result

    def message(self):
        return self.git('log', '-1', '--format=%B').strip()

    def commits(self):
        return int(self.git('rev-list', '--count', 'HEAD'))

    def test_an_updated_github_input_shows_both_commits_and_a_compare_link(self):
        result = self.update(BEFORE, AFTER)
        self.assertEqual(result.stdout, f'''
✓ 2 inputs updated

  claude-code
    376fb18 (2026-11-12) → 2c0782e (2026-11-13)
    https://github.com/sadjow/claude-code-nix/compare/{CLAUDE_OLD}...{CLAUDE_NEW}

  nixpkgs
    ac588ef (2026-11-08) → f1e5c35 (2026-11-13)
    https://github.com/NixOS/nixpkgs/compare/{NIXPKGS_OLD}...{NIXPKGS_NEW}

''')
        self.assertEqual(self.log.read_text().splitlines(), ['flake update'])
        self.assertEqual(self.commits(), 1, 'without --save nothing is committed')

    def test_save_commits_the_lock_with_a_note_for_each_input(self):
        result = self.update(BEFORE, AFTER, '--save')
        self.assertIn('✓ Committed: chore: upgrade claude-code and nixpkgs inputs', result.stdout)
        # The same words as the commits bin/update wrote when it read nix's output.
        self.assertEqual(self.message(), f'''chore: upgrade claude-code and nixpkgs inputs

### claude-code

- **Source:** https://github.com/sadjow/claude-code-nix
- **Update:** `376fb18` (2026-11-12) → `2c0782e` (2026-11-13)
- **Compare:** https://github.com/sadjow/claude-code-nix/compare/{CLAUDE_OLD}...{CLAUDE_NEW}

### nixpkgs

- **Source:** https://github.com/NixOS/nixpkgs
- **Update:** `ac588ef` (2026-11-08) → `f1e5c35` (2026-11-13)
- **Compare:** https://github.com/NixOS/nixpkgs/compare/{NIXPKGS_OLD}...{NIXPKGS_NEW}''')
        self.assertEqual(self.commits(), 2)
        self.assertEqual(self.git('status', '--porcelain'), '', 'flake.lock must be committed')

    def test_a_new_input_is_listed_as_added(self):
        vicinae = github('vicinaehq', 'vicinae', rev('1'), '2026-11-13')
        before = flake({'nixpkgs': BEFORE['nodes']['nixpkgs']['locked']})
        after = flake({'nixpkgs': BEFORE['nodes']['nixpkgs']['locked'], 'vicinae': vicinae})
        result = self.update(before, after, '--save')
        self.assertTrue(result.stdout.startswith('''
✓ 1 input added

  vicinae
    added 1111111 (2026-11-13)
    https://github.com/vicinaehq/vicinae

'''), result.stdout)
        self.assertEqual(self.message(), '''chore: upgrade vicinae input

### vicinae

- **Source:** https://github.com/vicinaehq/vicinae
- **Added:** `1111111` (2026-11-13)''')

    def test_a_removed_input_is_listed_as_removed(self):
        libxml2 = github('NixOS', 'nixpkgs', rev('2'), '2025-05-30')
        before = flake({'nixpkgs': BEFORE['nodes']['nixpkgs']['locked'], 'nixpkgs-libxml2': libxml2})
        after = flake({'nixpkgs': BEFORE['nodes']['nixpkgs']['locked']})
        result = self.update(before, after, '--save')
        self.assertTrue(result.stdout.startswith('''
✓ 1 input removed

  nixpkgs-libxml2
    removed 2222222 (2025-05-30)
    https://github.com/NixOS/nixpkgs

'''), result.stdout)
        self.assertEqual(self.message(), '''chore: upgrade nixpkgs-libxml2 input

### nixpkgs-libxml2

- **Source:** https://github.com/NixOS/nixpkgs
- **Removed:** `2222222` (2025-05-30)''')

    def test_an_input_off_github_has_no_compare_link(self):
        def hare(revision, date):
            return {'type': 'sourcehut', 'owner': '~sircmpwn', 'repo': 'hare', 'rev': revision,
                    'lastModified': day(date)}

        def tool(revision, date):
            return {'type': 'git', 'url': 'https://codeberg.org/someone/tool', 'ref': 'refs/heads/main',
                    'rev': revision, 'lastModified': day(date)}

        before = flake({'hare': hare(rev('3'), '2026-11-01'), 'tool': tool(rev('5'), '2026-11-02')})
        after = flake({'hare': hare(rev('4'), '2026-11-10'), 'tool': tool(rev('6'), '2026-11-11')})
        result = self.update(before, after, '--save')
        git = 'git+https://codeberg.org/someone/tool?ref=refs/heads/main&rev='
        self.assertTrue(result.stdout.startswith(f'''
✓ 2 inputs updated

  hare
    3333333 (2026-11-01) → 4444444 (2026-11-10)

  tool
    {git}{rev('5')} (2026-11-02)
    → {git}{rev('6')} (2026-11-11)

'''), result.stdout)
        self.assertEqual(self.message(), f'''chore: upgrade hare and tool inputs

### hare

- **Source:** https://git.sr.ht/~sircmpwn/hare
- **Update:** `3333333` (2026-11-01) → `4444444` (2026-11-10)

### tool

- `{git}{rev('5')}` (2026-11-02)
- → `{git}{rev('6')}` (2026-11-11)''')

    def test_inputs_of_inputs_are_named_by_path_in_the_order_nix_lists_them(self):
        def inputs(codex, utils, numen):
            return {
                'codex-cli-nix': github('sadjow', 'codex-cli-nix', codex, '2026-11-13'),
                'codex-cli-nix/flake-utils': github('numtide', 'flake-utils', utils, '2026-11-11'),
                'codex-cli-nix/nixpkgs': ['nixpkgs'],
                'nixpkgs': HOME_MANAGER,
                'vicinae': github('vicinaehq', 'vicinae', rev('7'), '2026-11-10'),
                'vicinae/numen': github('vicinaehq', 'numen', numen, '2026-11-09'),
            }

        before = flake(inputs(rev('1'), rev('3'), rev('5')))
        after = inputs(rev('2'), rev('4'), rev('6'))
        after['vicinae-extensions'] = github('vicinaehq', 'extensions', rev('8'), '2026-11-14')
        # It pins nothing of its own, so it isn't listed.
        after['vicinae-extensions/nixpkgs'] = ['nixpkgs']
        result = self.update(before, flake(after), '--save')
        # vicinae/numen sorts as a list of names, so before vicinae-extensions.
        self.assertIn('✓ 4 inputs changed: 3 updated, 1 added', result.stdout)
        self.assertEqual(self.message().splitlines()[0], 'chore: upgrade codex-cli-nix, '
                         'codex-cli-nix/flake-utils, vicinae/numen and vicinae-extensions inputs')
        self.assertIn('''### codex-cli-nix/flake-utils

- **Source:** https://github.com/numtide/flake-utils
- **Update:** `3333333` (2026-11-11) → `4444444` (2026-11-11)
- **Compare:** https://github.com/numtide/flake-utils/compare/''', self.message())

    def test_an_input_that_starts_to_follow_another_says_so(self):
        nixpkgs = github('NixOS', 'nixpkgs', rev('9'), '2026-05-15')
        before = flake({'vicinae': github('vicinaehq', 'vicinae', rev('7'), '2026-11-10'),
                        'vicinae/nixpkgs': nixpkgs})
        after = flake({'vicinae': github('vicinaehq', 'vicinae', rev('7'), '2026-11-10'),
                       'vicinae/nixpkgs': ['nixpkgs-unstable'], 'nixpkgs-unstable': nixpkgs})
        result = self.update(before, after, '--save')
        self.assertIn(f'''
  vicinae/nixpkgs
    github:NixOS/nixpkgs/{rev('9')} (2026-05-15)
    → follows 'nixpkgs-unstable'
''', result.stdout)
        self.assertIn(f'''### vicinae/nixpkgs

- `github:NixOS/nixpkgs/{rev('9')}` (2026-05-15)
- → `follows 'nixpkgs-unstable'`''', self.message())

    def test_no_change_commits_nothing(self):
        result = self.update(BEFORE, BEFORE, '--save')
        self.assertEqual(result.stdout, '• No inputs changed.\n✗ No inputs were updated; nothing to commit.\n')
        self.assertEqual(self.commits(), 1)

    def test_a_failed_update_stops_with_one_line_and_commits_nothing(self):
        result = self.update(BEFORE, None, '--save', success=False)
        self.assertEqual(result.stderr.strip().splitlines()[-1], '✗ nix flake update failed.')
        self.assertEqual(result.stdout, '')
        self.assertEqual(self.commits(), 1)


if __name__ == '__main__':
    unittest.main()
