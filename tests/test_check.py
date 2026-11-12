"""Run with: nix develop --command python3 -B -m unittest discover -s tests -v."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]

# A stand-in for nix. It logs each call, answers `nix flake check` with the
# status in check-status, and answers `nix eval` with before.json for a commit
# (a git+file:// flake) or after.json for the working tree.
NIX = r'''
echo "$*" >> "$FAKE_DIR/nix.log"
case "$1 $2" in
  "flake check")
    exit "$(cat "$FAKE_DIR/check-status" 2>/dev/null || echo 0)" ;;
  "eval --json")
    case "$3" in
      git+file://*) answer="$FAKE_DIR/before.json" ;;
      *) answer="$FAKE_DIR/after.json" ;;
    esac
    [ -f "$answer" ] || { echo "error: evaluation broke" >&2; exit 1; }
    cat "$answer" ;;
esac
'''

LINUX = 'x86_64-linux'
MAC = 'aarch64-darwin'


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.fakes = self.root / 'fake'
        self.env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', FAKE_DIR=str(self.fakes),
                        PATH=str(self.fakes) + os.pathsep + os.environ['PATH'])
        self.write('bin/check', (SOURCE / 'bin/check').read_text())
        self.write('.gitignore', 'fake/\n')
        self.fake('nix', NIX)
        self.fake('nix-diff', 'echo "$*" >> "$FAKE_DIR/nix-diff.log"')
        self.run_command('git', 'init', '-q')
        self.first = self.commit('one')
        self.write('flake.nix', '{ }\n')
        self.head = self.commit('two')

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def fake(self, name, body):
        self.write(f'fake/{name}', '#!/bin/sh\n' + body + '\n').chmod(0o755)

    def run_command(self, *command, success=True):
        result = subprocess.run(command, cwd=self.root, env=self.env,
                                stdin=subprocess.DEVNULL, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def commit(self, message):
        self.run_command('git', 'add', '.')
        self.run_command('git', '-c', 'user.name=Test', '-c', 'user.email=test@example.com',
                         '-c', 'commit.gpgsign=false', 'commit', '-q', '-m', message)
        return self.run_command('git', 'rev-parse', 'HEAD').stdout.strip()

    def check(self, *args, **kwargs):
        result = self.run_command('xonsh', '--no-rc', 'bin/check', *args, **kwargs)
        self.assertNotIn('Traceback', result.stdout + result.stderr)
        return result

    def log(self, name='nix.log'):
        path = self.fakes / name
        return path.read_text().splitlines() if path.exists() else []

    def derivations(self, before, after):
        """What the stand-in nix answers for the commit and for the working tree."""
        for name, checks in (('before.json', before), ('after.json', after)):
            (self.fakes / name).write_text(json.dumps(checks))

    def states(self, result):
        """{check name: state} from the lines --same prints."""
        return {line.split()[2]: line.split()[0] for line in result.stdout.splitlines()
                if line.split()[:1] and line.split()[0] in ('same', 'changed', 'added', 'removed')}

    def test_flags_pick_what_nix_flake_check_runs(self):
        cases = [([], 'flake check'),
                 (['--eval'], 'flake check --all-systems --no-build'),
                 (['--all-systems'], 'flake check --all-systems')]
        for flags, expected in cases:
            with self.subTest(flags=flags):
                (self.fakes / 'nix.log').unlink(missing_ok=True)
                self.check(*flags)
                self.assertEqual(self.log(), [expected])

    def test_failed_check_fails_with_one_plain_line(self):
        (self.fakes / 'check-status').write_text('1')
        for flags in ([], ['--eval'], ['--all-systems']):
            with self.subTest(flags=flags):
                result = self.check(*flags, success=False)
                self.assertIn('✗ nix flake check', result.stderr)
                self.assertEqual(len(result.stderr.strip().splitlines()), 1, result.stderr)

    def test_same_compares_head_with_the_working_tree(self):
        checks = {LINUX: {'nelson@framework': '/nix/store/a.drv', 'nixos-framework': '/nix/store/b.drv'},
                  MAC: {'darwin-mac': '/nix/store/c.drv'}}
        self.derivations(checks, checks)
        result = self.check('--same')
        self.assertEqual(self.states(result), {'nelson@framework': 'same', 'nixos-framework': 'same',
                                               'darwin-mac': 'same'})
        self.assertIn('All 3 derivations are the same', result.stdout)
        commit, tree = self.log()
        self.assertTrue(commit.startswith('eval --json git+file://'), commit)
        self.assertIn(f'?rev={self.head}#checks --apply ', commit)
        self.assertTrue(tree.startswith('eval --json .#checks --apply '), tree)

    def test_changed_added_and_removed_all_count_as_different(self):
        self.derivations({LINUX: {'kept': '/nix/store/a.drv', 'edited': '/nix/store/b.drv',
                                  'gone': '/nix/store/c.drv'}},
                         {LINUX: {'kept': '/nix/store/a.drv', 'edited': '/nix/store/z.drv'},
                          MAC: {'new': '/nix/store/d.drv'}})
        result = self.check('--same', success=False)
        self.assertEqual(self.states(result), {'kept': 'same', 'edited': 'changed',
                                               'gone': 'removed', 'new': 'added'})
        self.assertIn('3 of 4 derivations differ', result.stderr)
        self.assertIn('--why', result.stderr)
        self.assertEqual(self.log('nix-diff.log'), [])

    def test_rev_picks_the_commit_to_compare_with(self):
        self.derivations({}, {})
        for rev in ('HEAD~1', self.first, self.first[:8]):
            with self.subTest(rev=rev):
                (self.fakes / 'nix.log').unlink(missing_ok=True)
                self.check('--same', rev)
                self.assertIn(f'?rev={self.first}#checks', self.log()[0])

    def test_unknown_rev_stops_before_evaluating(self):
        result = self.check('--same', 'nope', success=False)
        self.assertIn("Unknown revision 'nope'", result.stderr)
        self.assertEqual(self.log(), [])

    def test_why_diffs_only_the_changed_pairs(self):
        self.derivations({LINUX: {'kept': '/nix/store/a.drv', 'edited': '/nix/store/b.drv',
                                  'gone': '/nix/store/c.drv'}},
                         {LINUX: {'kept': '/nix/store/a.drv', 'edited': '/nix/store/z.drv',
                                  'new': '/nix/store/d.drv'}})
        result = self.check('--same', '--why', success=False)
        self.assertEqual(self.log('nix-diff.log'), ['/nix/store/b.drv /nix/store/z.drv'])
        self.assertIn('no pair to compare', result.stdout)
        self.assertNotIn('--why', result.stderr)

    def test_untracked_nix_files_get_a_hint(self):
        self.derivations({}, {})
        self.write('home/programs/new one/new.nix', '{ }\n')
        self.write('notes.txt', 'not nix\n')
        result = self.check('--same')
        self.assertIn('git add', result.stdout)
        self.assertIn('home/programs/new one/new.nix', result.stdout)
        self.assertNotIn('notes.txt', result.stdout)

    def test_failed_evaluation_shows_the_error_and_stops(self):
        (self.fakes / 'before.json').write_text('{}')
        result = self.check('--same', success=False)
        self.assertIn('error: evaluation broke', result.stderr)
        self.assertIn('Could not evaluate the working tree', result.stderr)

    def test_why_needs_same(self):
        result = self.run_command('xonsh', '--no-rc', 'bin/check', '--why', success=False)
        self.assertIn('Usage:', result.stdout + result.stderr)
        self.assertEqual(self.log(), [])


if __name__ == '__main__':
    unittest.main()
