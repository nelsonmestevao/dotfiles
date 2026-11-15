"""Run with: bin/test.

bin/update in a throwaway repo, for what needs a real run: the commit --save
writes, and what happens when there is nothing to commit or the update fails.
A stand-in nix answers `nix flake update` by swapping in another lock from
fixtures/locks, so nothing is fetched. Which inputs changed is worked out by
lib/lockChanges.nix, and tests/lib.nix tests that.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
LOCKS = ROOT / 'tests/fixtures/locks'

# `nix flake update` copies $AFTER over flake.lock, or fails like a broken
# download when $AFTER is empty. It logs each call.
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


class UpdateTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='update test ')
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        self.repo = self.dir / 'repo'
        for name in ('bin/update', 'scripts/common.xsh', 'lib/lockChanges.nix'):
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
                        LOG=str(self.log), GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM='1',
                        GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.com',
                        GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.com')
        self.env.pop('NIX_CONFIG', None)
        self.git('init', '-q')

    def git(self, *args):
        result = subprocess.run(['git', *args], cwd=self.repo, env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def update(self, before, after, success=True):
        """Commits the fixture lock `before` as flake.lock, then runs
        `bin/update --save`, where `nix flake update` writes the fixture lock
        `after`. With `after` None, nix fails."""
        shutil.copy(LOCKS / f'{before}.lock', self.repo / 'flake.lock')
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'start')
        env = dict(self.env, AFTER=str(LOCKS / f'{after}.lock') if after else '')
        result = subprocess.run([shutil.which('xonsh'), '--no-rc', 'bin/update', '--save'], cwd=self.repo,
                                env=env, stdin=subprocess.DEVNULL, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        self.assertNotIn('Traceback', result.stdout + result.stderr)
        # Neither stream is a terminal here, so neither gets color codes.
        self.assertNotIn('\033', result.stdout + result.stderr)
        self.assertEqual(self.log.read_text().splitlines(), ['flake update'])
        return result

    def commits(self):
        return int(self.git('rev-list', '--count', 'HEAD'))

    def test_save_commits_the_lock_with_a_note_for_each_input(self):
        result = self.update('before', 'after')
        self.assertTrue(result.stdout.startswith(SUMMARY), result.stdout)
        self.assertIn(f'✓ Committed: {MESSAGE.splitlines()[0]}', result.stdout)
        self.assertEqual(self.git('log', '-1', '--format=%B').strip(), MESSAGE)
        self.assertEqual(self.commits(), 2)
        self.assertEqual(self.git('status', '--porcelain'), '', 'flake.lock must be committed')

    def test_no_change_commits_nothing(self):
        result = self.update('before', 'before')
        self.assertEqual(result.stdout, '• No inputs changed.\n✗ No inputs were updated; nothing to commit.\n')
        self.assertEqual(self.commits(), 1)

    def test_a_failed_update_stops_with_one_line_and_commits_nothing(self):
        result = self.update('before', None, success=False)
        self.assertEqual(result.stderr.strip().splitlines()[-1], '✗ nix flake update failed.')
        self.assertEqual(result.stdout, '')
        self.assertEqual(self.commits(), 1)


# What bin/update prints and commits for fixtures/locks/before.lock and
# after.lock. The title names only the inputs that moved. The nixpkgs section
# has the revisions of a real upgrade commit (87b99c60), and reads exactly
# like it.
SUMMARY = '''
✓ 9 inputs changed: 7 updated, 1 added, 1 removed

  hare
    3333333 (2026-11-01) → 4444444 (2026-11-10)

  inkscape
    aaaaaaa (2026-11-02) → bbbbbbb (2026-11-12)
    https://gitlab.com/inkscape/inkscape/-/compare/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa...bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

  nixpkgs
    ac588ef (2026-11-08) → f1e5c35 (2026-11-13)
    https://github.com/NixOS/nixpkgs/compare/ac588ef1c914865dad517b337ea0eb9694a4021c...f1e5c356f35d07e7b71a6b5e6c9338e0b029e0c0

  tool
    5555555 (2026-11-02) → 6666666 (2026-11-11)

  vicinae
    7777777 (2026-11-10) → ccccccc (2026-11-13)
    https://github.com/vicinaehq/vicinae/compare/7777777777777777777777777777777777777777...cccccccccccccccccccccccccccccccccccccccc

  vicinae/nixpkgs
    9999999 (2026-05-15) → follows 'nixpkgs'

  vicinae/numen
    1111111 (2026-11-09) → 2222222 (2026-11-11)
    https://github.com/vicinaehq/numen/compare/1111111111111111111111111111111111111111...2222222222222222222222222222222222222222

  vicinae-extensions
    added 8888888 (2026-11-14)
    https://github.com/vicinaehq/extensions

  zen-browser
    removed ddddddd (2026-11-07)
    https://github.com/youwen5/zen-browser-flake

'''
MESSAGE = '''chore: upgrade hare, inkscape, nixpkgs, tool, vicinae, vicinae/nixpkgs and vicinae/numen inputs

### hare

- **Source:** https://git.sr.ht/~sircmpwn/hare
- **Update:** `3333333` (2026-11-01) → `4444444` (2026-11-10)

### inkscape

- **Source:** https://gitlab.com/inkscape/inkscape
- **Update:** `aaaaaaa` (2026-11-02) → `bbbbbbb` (2026-11-12)
- **Compare:** https://gitlab.com/inkscape/inkscape/-/compare/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa...bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

### nixpkgs

- **Source:** https://github.com/NixOS/nixpkgs
- **Update:** `ac588ef` (2026-11-08) → `f1e5c35` (2026-11-13)
- **Compare:** https://github.com/NixOS/nixpkgs/compare/ac588ef1c914865dad517b337ea0eb9694a4021c...f1e5c356f35d07e7b71a6b5e6c9338e0b029e0c0

### tool

- **Update:** `5555555` (2026-11-02) → `6666666` (2026-11-11)

### vicinae

- **Source:** https://github.com/vicinaehq/vicinae
- **Update:** `7777777` (2026-11-10) → `ccccccc` (2026-11-13)
- **Compare:** https://github.com/vicinaehq/vicinae/compare/7777777777777777777777777777777777777777...cccccccccccccccccccccccccccccccccccccccc

### vicinae/nixpkgs

- **Source:** https://github.com/NixOS/nixpkgs
- **Update:** `9999999` (2026-05-15) → `follows 'nixpkgs'`

### vicinae/numen

- **Source:** https://github.com/vicinaehq/numen
- **Update:** `1111111` (2026-11-09) → `2222222` (2026-11-11)
- **Compare:** https://github.com/vicinaehq/numen/compare/1111111111111111111111111111111111111111...2222222222222222222222222222222222222222

### vicinae-extensions

- **Source:** https://github.com/vicinaehq/extensions
- **Added:** `8888888` (2026-11-14)

### zen-browser

- **Source:** https://github.com/youwen5/zen-browser-flake
- **Removed:** `ddddddd` (2026-11-07)'''


if __name__ == '__main__':
    unittest.main()
