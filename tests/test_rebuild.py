"""Run with: bin/test.

bin/rebuild and bin/build with a stand-in `nh` that records each call and
fails when told to, so nothing is built or switched. They check what happens
when a step fails: the helper stops with one plain line, says what it left
undone, and runs nothing it shouldn't.
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]

# What nh calls the system on the machine running the tests.
OS = 'darwin' if sys.platform == 'darwin' else 'os'

# Records `nh <args>` and NIX_CONFIG. It fails when its first argument is in
# $FAIL (like "os home"), and acts as if Ctrl-C hit it when it is $INTERRUPT.
NH = '''#!/bin/sh
echo "$*" >> "$LOG"
printf '%s\\n---\\n' "$NIX_CONFIG" >> "$LOG.config"
[ "$1" = "$INTERRUPT" ] && kill -INT $$
[ "$1" = "$KILL" ] && kill -KILL $$
case " $FAIL " in *" $1 "*) echo "nh $1 broke" >&2; exit 1 ;; esac
'''


class HelperTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='rebuild test ')
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        # The helpers run in a throwaway copy of the repo. If the stand-in nh
        # were ever missed, a real one would find no flake here and change
        # nothing.
        self.repo = self.dir / 'repo'
        for name in ('bin/rebuild', 'bin/build', 'scripts/common.xsh'):
            (self.repo / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(ROOT / name, self.repo / name)
        bin_dir = self.dir / 'stub'
        bin_dir.mkdir()
        stub = bin_dir / 'nh'
        stub.write_text(NH)
        stub.chmod(0o755)
        self.log = self.dir / 'nh.log'
        self.xonsh = shutil.which('xonsh')
        self.env = dict(os.environ, PATH=f'{bin_dir}{os.pathsep}{os.environ["PATH"]}',
                        LOG=str(self.log), FAIL='', INTERRUPT='', KILL='')
        self.env.pop('NIX_CONFIG', None)

    def helper(self, name, *args, fail='', interrupt='', kill='', nix_config=None, without_nh=False):
        env = dict(self.env, FAIL=fail, INTERRUPT=interrupt, KILL=kill)
        if nix_config is not None:
            env['NIX_CONFIG'] = nix_config
        if without_nh:
            env['PATH'] = '/usr/bin:/bin'
        return subprocess.run([self.xonsh, '--no-rc', f'bin/{name}', *args], cwd=self.repo, env=env,
                              text=True, capture_output=True)

    def config(self):
        return (self.dir / 'nh.log.config').read_text()

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []


class RebuildTests(HelperTests):
    def test_it_switches_the_system_then_the_home(self):
        result = self.helper('rebuild')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [f'{OS} switch .', 'home switch .'])

    def test_a_failed_system_switch_leaves_the_home_alone(self):
        result = self.helper('rebuild', fail=OS)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.calls(), [f'{OS} switch .'], 'the home must not be switched')
        self.assertIn(f'✗ nh {OS} switch . failed; home not switched.', result.stderr)
        self.assertNotIn('Traceback', result.stderr)
        self.assertNotIn('CalledProcessError', result.stderr)

    def test_a_failed_home_switch_says_so(self):
        result = self.helper('rebuild', 'home', fail='home')
        self.assertEqual(result.returncode, 1)
        self.assertIn('✗ nh home switch . failed.', result.stderr)

    def test_it_keeps_what_nix_config_already_holds(self):
        result = self.helper('rebuild', 'home', nix_config='access-tokens = github.com=secret')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('access-tokens = github.com=secret', self.config())
        self.assertIn('extra-experimental-features = nix-command flakes', self.config())

    def test_ctrl_c_stops_it_and_says_what_was_left(self):
        result = self.helper('rebuild', interrupt=OS)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.calls(), [f'{OS} switch .'])
        self.assertIn('Interrupted; home not switched.', result.stderr)

    def test_a_missing_nh_is_one_plain_line(self):
        result = self.helper('rebuild', without_nh=True)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr.strip().splitlines(),
                         ['✗ nh is missing. Run this from the repo, so it starts in the dev shell.'])
        self.assertEqual(self.calls(), [])

    def test_boot_on_a_mac_is_refused(self):
        if OS != 'darwin':
            self.skipTest('nix-darwin only runs on a Mac')
        result = self.helper('rebuild', '--boot')
        self.assertEqual(result.returncode, 1)
        self.assertIn('nix-darwin has no --boot', result.stderr)
        self.assertEqual(self.calls(), [], 'nothing may be switched')


class BuildTests(HelperTests):
    def test_it_builds_both_even_when_the_first_fails(self):
        result = self.helper('build', fail=OS)
        self.assertEqual(result.returncode, 1)
        self.assertEqual([call.split()[:2] for call in self.calls()], [[OS, 'build'], ['home', 'build']])
        self.assertIn(f'✗ nh {OS} build failed', result.stderr)
        self.assertNotIn('Built.', result.stdout)

    def test_a_killed_build_is_a_failure_not_ctrl_c(self):
        result = self.helper('build', kill=OS)
        self.assertEqual(result.returncode, 1)
        self.assertEqual([call.split()[0] for call in self.calls()], [OS, 'home'], 'the home build must still run')
        self.assertNotIn('Interrupted', result.stderr)

    def test_ctrl_c_stops_every_build(self):
        result = self.helper('build', interrupt=OS)
        self.assertEqual(result.returncode, 1)
        self.assertEqual([call.split()[0] for call in self.calls()], [OS], 'the home build must not start')
        self.assertIn('Interrupted.', result.stderr)

    def test_it_keeps_what_nix_config_already_holds(self):
        result = self.helper('build', 'home', nix_config='access-tokens = github.com=secret')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('access-tokens = github.com=secret', self.config())

    def test_it_says_built_when_both_pass(self):
        result = self.helper('build')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Built. Nothing was switched.', result.stdout)


if __name__ == '__main__':
    unittest.main()
