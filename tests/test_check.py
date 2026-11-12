"""Run with: bin/test."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]

# A stand-in for nix. It logs each call and answers from files in $FAKE_DIR:
#   nix flake check      exits with the status in check-status
#   nix eval             prints before.json for a commit (a git+file:// flake)
#                        or after.json for the working tree, and writes
#                        before.err or after.err to stderr when it exists
#   nix derivation show  prints the derivation from show/<name>, or one with
#                        an empty environment
NIX = r'''
echo "$*" >> "$FAKE_DIR/nix.log"
case "$1 $2" in
  "flake check")
    exit "$(cat "$FAKE_DIR/check-status" 2>/dev/null || echo 0)" ;;
  "eval --json")
    case "$3" in
      git+file://*) side=before ;;
      *) side=after ;;
    esac
    [ -f "$FAKE_DIR/$side.err" ] && cat "$FAKE_DIR/$side.err" >&2
    [ -f "$FAKE_DIR/$side.json" ] || { echo "error: evaluation broke" >&2; exit 1; }
    cat "$FAKE_DIR/$side.json" ;;
  "derivation show")
    cat "$FAKE_DIR/show/$(basename "$3")" 2>/dev/null || echo '{"derivations":{"x.drv":{"env":{}}}}' ;;
esac
'''

LINUX = 'x86_64-linux'
MAC = 'aarch64-darwin'
ONE = {LINUX: {'nelson@framework': '/nix/store/a.drv'}}


class CheckTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'repo'
        self.fakes = Path(self.temp.name) / 'fake'
        self.env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1', FAKE_DIR=str(self.fakes),
                        PATH=str(self.fakes) + os.pathsep + os.environ['PATH'])
        self.write('bin/check', (SOURCE / 'bin/check').read_text())
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
        path = self.fakes / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('#!/bin/sh\n' + body + '\n')
        path.chmod(0o755)

    def run_command(self, *command, success=True, cwd=None):
        result = subprocess.run(command, cwd=cwd or self.root, env=self.env,
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
        # Neither stream is a terminal here, so neither gets color codes.
        self.assertNotIn('\033', result.stdout + result.stderr)
        return result

    def log(self, name='nix.log'):
        path = self.fakes / name
        return path.read_text().splitlines() if path.exists() else []

    def evaluated(self):
        """The flake each `nix eval` call read. The two run at once, so their
        order in the log is not fixed."""
        return sorted(line.split()[2] for line in self.log() if line.startswith('eval '))

    def derivations(self, before, after):
        """What the stand-in nix answers for the commit and for the working tree."""
        for name, checks in (('before.json', before), ('after.json', after)):
            (self.fakes / name).write_text(json.dumps(checks))

    def states(self, result):
        """{check name: state} from the lines --same prints."""
        return {line.split()[2]: line.split()[0] for line in result.stdout.splitlines()
                if line.split()[:1] and line.split()[0] in ('same', 'changed', 'added', 'removed')}

    def test_flags_pick_what_nix_flake_check_runs(self):
        cases = [([], ['flake check --all-systems --no-build', 'flake check']),
                 (['--eval'], ['flake check --all-systems --no-build']),
                 (['--all-systems'], ['flake check --all-systems'])]
        for flags, expected in cases:
            with self.subTest(flags=flags):
                (self.fakes / 'nix.log').unlink(missing_ok=True)
                self.check(*flags)
                self.assertEqual(self.log(), expected)

    def test_failed_check_fails_with_one_plain_line(self):
        (self.fakes / 'check-status').write_text('1')
        for flags in ([], ['--eval'], ['--all-systems']):
            with self.subTest(flags=flags):
                (self.fakes / 'nix.log').unlink(missing_ok=True)
                result = self.check(*flags, success=False)
                self.assertIn('✗ nix flake check', result.stderr)
                self.assertEqual(len(result.stderr.strip().splitlines()), 1, result.stderr)
                # A failed evaluation stops the plain check before it builds.
                self.assertEqual(len(self.log()), 1)

    def test_same_compares_head_with_the_working_tree(self):
        checks = {LINUX: {'nelson@framework': '/nix/store/a.drv', 'nixos-framework': '/nix/store/b.drv'},
                  MAC: {'darwin-mac': '/nix/store/c.drv'}}
        self.derivations(checks, checks)
        result = self.check('--same')
        self.assertEqual(self.states(result), {'nelson@framework': 'same', 'nixos-framework': 'same',
                                               'darwin-mac': 'same'})
        self.assertIn('All 3 derivations are the same', result.stdout)
        tree, commit = self.evaluated()
        self.assertEqual(tree, '.#checks')
        self.assertTrue(commit.startswith('git+file://'), commit)
        self.assertTrue(commit.endswith(f'?rev={self.head}#checks'), commit)

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

    def test_nothing_to_compare_is_a_failure(self):
        for before, after in [({}, {}), ({LINUX: {}}, {MAC: {}})]:
            with self.subTest(before=before, after=after):
                self.derivations(before, after)
                result = self.check('--same', success=False)
                self.assertIn('Nothing to compare', result.stderr)
                self.assertNotIn('are the same', result.stdout)

    def test_rev_picks_the_commit_to_compare_with(self):
        self.derivations(ONE, ONE)
        for rev in ('HEAD~1', self.first, self.first[:8]):
            with self.subTest(rev=rev):
                (self.fakes / 'nix.log').unlink(missing_ok=True)
                self.check('--same', rev)
                self.assertTrue(self.evaluated()[1].endswith(f'?rev={self.first}#checks'))

    def test_unknown_rev_stops_before_evaluating(self):
        result = self.check('--same', 'nope', success=False)
        self.assertIn("Unknown revision 'nope'", result.stderr)
        self.assertEqual(self.log(), [])

    def test_shallow_clone_tells_nix_and_explains_a_failure(self):
        clone = Path(self.temp.name) / 'shallow'
        self.run_command('git', 'clone', '-q', '--depth', '1', f'file://{self.root}', str(clone))
        self.derivations(ONE, ONE)
        self.run_command('xonsh', '--no-rc', 'bin/check', '--same', cwd=clone)
        self.assertTrue(self.evaluated()[1].endswith(f'?rev={self.head}&shallow=1#checks'))

        (self.fakes / 'before.json').unlink()
        result = self.run_command('xonsh', '--no-rc', 'bin/check', '--same', cwd=clone, success=False)
        self.assertIn('This clone is shallow', result.stderr)
        # The full clone gets neither the flag nor the hint.
        (self.fakes / 'nix.log').unlink()
        result = self.check('--same', success=False)
        self.assertNotIn('shallow', result.stderr)
        self.assertNotIn('shallow', ' '.join(self.evaluated()))

    def test_why_diffs_only_the_changed_pairs(self):
        self.derivations({LINUX: {'kept': '/nix/store/a.drv', 'edited': '/nix/store/b.drv',
                                  'gone': '/nix/store/c.drv'}},
                         {LINUX: {'kept': '/nix/store/a.drv', 'edited': '/nix/store/z.drv',
                                  'new': '/nix/store/d.drv'}})
        result = self.check('--same', '--why', success=False)
        self.assertEqual(self.log('nix-diff.log'), ['/nix/store/b.drv /nix/store/z.drv'])
        self.assertIn('no pair to compare', result.stdout)
        self.assertNotIn('--why', result.stderr)

    def test_why_looks_inside_an_eval_only_check(self):
        """The nixos-<host> and darwin-<host> checks only carry the path of the
        system's derivation. --why compares those, in either JSON shape."""
        self.derivations({LINUX: {'nixos-framework': '/nix/store/old-eval.drv'}},
                         {LINUX: {'nixos-framework': '/nix/store/new-eval.drv'}})
        shapes = {
            'nested': lambda inner: {'derivations': {'x.drv': {'env': {'drvPath': inner}}}, 'version': 4},
            'flat': lambda inner: {'/nix/store/x.drv': {'env': {'drvPath': inner}}},
        }
        (self.fakes / 'show').mkdir()
        for name, shape in shapes.items():
            with self.subTest(shape=name):
                (self.fakes / 'nix-diff.log').unlink(missing_ok=True)
                (self.fakes / 'show/old-eval.drv').write_text(json.dumps(shape('/nix/store/old-system.drv')))
                (self.fakes / 'show/new-eval.drv').write_text(json.dumps(shape('/nix/store/new-system.drv')))
                self.check('--same', '--why', success=False)
                self.assertEqual(self.log('nix-diff.log'), ['/nix/store/old-system.drv /nix/store/new-system.drv'])

    def test_untracked_files_get_a_hint(self):
        self.derivations(ONE, ONE)
        self.write('home/programs/new one/new.nix', '{ }\n')
        self.write('home/programs/café/fix.patch', 'a patch\n')
        result = self.check('--same')
        self.assertIn('git add', result.stderr)
        # Paths print as they are: no quotes, no escapes.
        self.assertIn('    home/programs/new one/new.nix\n', result.stderr)
        self.assertIn('    home/programs/café/fix.patch\n', result.stderr)
        self.assertNotIn('more', result.stderr)

        for number in range(12):
            self.write(f'extra/{number:02}.txt', 'x\n')
        result = self.check('--same')
        listed = [line for line in result.stderr.splitlines() if line.startswith('    ')]
        self.assertEqual(len(listed), 11, result.stderr)
        self.assertEqual(listed[-1], '    and 4 more')

    def test_no_hint_when_everything_is_tracked(self):
        self.derivations(ONE, ONE)
        result = self.check('--same')
        self.assertEqual(result.stderr, '')

    def test_warnings_from_both_sides_are_shown(self):
        self.derivations(ONE, ONE)
        (self.fakes / 'before.err').write_text('warning: old option\n')
        (self.fakes / 'after.err').write_text('warning: renamed option\nwarning: renamed option\n\nwarning: other\n')
        result = self.check('--same')
        self.assertIn('Messages from HEAD', result.stderr)
        self.assertIn('  warning: old option\n', result.stderr)
        self.assertIn('Messages from the working tree:\n  warning: renamed option  (×2)\n  warning: other\n',
                      result.stderr)
        self.assertIn('All 1 derivations are the same', result.stdout)

    def test_failed_evaluation_shows_the_error_and_stops(self):
        (self.fakes / 'before.json').write_text(json.dumps(ONE))
        (self.fakes / 'before.err').write_text('warning: from the commit\n')
        result = self.check('--same', success=False)
        self.assertIn('warning: from the commit', result.stderr)
        self.assertIn('Messages from the working tree:\nerror: evaluation broke', result.stderr)
        self.assertIn('Could not evaluate the working tree', result.stderr)
        self.assertEqual(self.states(result), {})

    def test_list_prints_the_working_tree_as_json(self):
        checks = {LINUX: {'nelson@framework': '/nix/store/a.drv', 'nixos-framework': '/nix/store/b.drv'},
                  MAC: {'darwin-mac': '/nix/store/c.drv'}}
        self.derivations({}, checks)
        (self.fakes / 'after.err').write_text('warning: renamed option\n')
        result = self.check('--list')
        # stdout is the JSON alone; Nix's warnings go to stderr.
        self.assertEqual(json.loads(result.stdout), checks)
        self.assertIn('warning: renamed option', result.stderr)
        self.assertEqual(self.evaluated(), ['.#checks'])

    def test_list_fails_when_the_working_tree_does_not_evaluate(self):
        result = self.check('--list', success=False)
        self.assertEqual(result.stdout, '')
        self.assertIn('error: evaluation broke', result.stderr)
        self.assertIn('Could not evaluate the working tree', result.stderr)

    def test_why_needs_same(self):
        result = self.run_command('xonsh', '--no-rc', 'bin/check', '--why', success=False)
        self.assertIn('Usage:', result.stdout + result.stderr)
        self.assertEqual(self.log(), [])


if __name__ == '__main__':
    unittest.main()
