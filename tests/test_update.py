"""Run with: bin/test."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]

# A stand-in for nix. `nix flake update` changes flake.lock and says so the
# way nix does, unless $UNCHANGED is set.
NIX = r'''#!/bin/sh
[ -n "$UNCHANGED" ] && exit 0
echo '{"new": true}' > flake.lock
cat >&2 <<'OUT'
warning: updating lock file '/repo/flake.lock':
• Updated input 'nixpkgs':
    'github:NixOS/nixpkgs/1111111111111111111111111111111111111111?narHash=sha256-old' (2026-11-01)
  → 'github:NixOS/nixpkgs/2222222222222222222222222222222222222222?narHash=sha256-new' (2026-11-10)
OUT
'''


class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'repo'
        fakes = Path(self.temp.name) / 'fake'
        self.env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', UNCHANGED='',
                        PATH=str(fakes) + os.pathsep + os.environ['PATH'],
                        GIT_AUTHOR_NAME='Test', GIT_AUTHOR_EMAIL='test@example.com',
                        GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.com')
        for name in ('bin/update', 'scripts/common.xsh'):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text((SOURCE / name).read_text())
        fakes.mkdir()
        (fakes / 'nix').write_text(NIX)
        (fakes / 'nix').chmod(0o755)
        (self.root / 'flake.lock').write_text('{"new": false}\n')
        (self.root / 'notes.txt').write_text('first\n')
        self.git('init', '-q')
        self.git('add', '.')
        self.git('commit', '-q', '-m', 'start')

    def git(self, *args):
        result = subprocess.run(['git', *args], cwd=self.root, env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def update(self, *args, **env):
        return subprocess.run([shutil.which('xonsh'), '--no-rc', 'bin/update', *args], cwd=self.root,
                              env=dict(self.env, **env), stdin=subprocess.DEVNULL, text=True,
                              capture_output=True)

    def test_it_lists_the_inputs_without_a_terminal_or_colours(self):
        result = self.update()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('✓ 1 input updated', result.stdout)
        self.assertIn('1111111 (2026-11-01) → 2222222 (2026-11-10)', result.stdout)
        self.assertIn('https://github.com/NixOS/nixpkgs/compare/1111111', result.stdout)
        self.assertNotIn('\033', result.stdout + result.stderr)
        # Without --save nothing is committed.
        self.assertEqual(self.git('log', '--format=%s'), 'start\n')

    def test_save_commits_only_the_lockfile(self):
        (self.root / 'notes.txt').write_text('second\n')
        self.git('add', 'notes.txt')
        result = self.update('--save')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git('log', '-1', '--format=%s'), 'chore: upgrade nixpkgs input\n')
        self.assertEqual(self.git('show', '--name-only', '--format='), 'flake.lock\n')
        # What was staged before is still staged, and not in the commit.
        self.assertEqual(self.git('diff', '--cached', '--name-only'), 'notes.txt\n')

    def test_save_commits_nothing_when_no_input_moved(self):
        result = self.update('--save', UNCHANGED='1')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('No inputs changed.', result.stderr)
        self.assertEqual(self.git('log', '--format=%s'), 'start\n')


if __name__ == '__main__':
    unittest.main()
