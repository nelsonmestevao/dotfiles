"""Run with: bin/test.

bin/rebuild and bin/build with a stand-in `nh` that records each call and
fails when told to, so nothing is built or switched. They check what happens
when a step fails: the helper stops with one plain line, says what it left
undone, and runs nothing it shouldn't.
"""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]

# What nh calls the system on the machine running the tests.
OS = 'darwin' if sys.platform == 'darwin' else 'os'

# Records `nh <args>` and NIX_CONFIG, and fails when its first argument is in
# $FAIL (like "os home").
NH = '''#!/bin/sh
echo "$*" >> "$LOG"
printf '%s\\n---\\n' "$NIX_CONFIG" >> "$LOG.config"
case " $FAIL " in *" $1 "*) echo "nh $1 broke" >&2; exit 1 ;; esac
'''


class HelperTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='rebuild test ')
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        stub = self.dir / 'nh'
        stub.write_text(NH)
        stub.chmod(0o755)
        self.log = self.dir / 'nh.log'
        self.env = dict(os.environ, PATH=f'{self.dir}{os.pathsep}{os.environ["PATH"]}',
                        LOG=str(self.log), FAIL='')
        self.env.pop('NIX_CONFIG', None)

    def helper(self, name, *args, fail='', nix_config=None):
        env = dict(self.env, FAIL=fail)
        if nix_config is not None:
            env['NIX_CONFIG'] = nix_config
        return subprocess.run(['xonsh', '--no-rc', f'bin/{name}', *args], cwd=ROOT, env=env,
                              text=True, capture_output=True)

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
        self.helper('rebuild', 'home', nix_config='access-tokens = github.com=secret')
        config = (self.dir / 'nh.log.config').read_text()
        self.assertIn('access-tokens = github.com=secret', config)
        self.assertIn('extra-experimental-features = nix-command flakes', config)


class BuildTests(HelperTests):
    def test_it_builds_both_even_when_the_first_fails(self):
        result = self.helper('build', fail=OS)
        self.assertEqual(result.returncode, 1)
        self.assertEqual([call.split()[:2] for call in self.calls()], [[OS, 'build'], ['home', 'build']])
        self.assertIn(f'nh {OS} build', result.stderr)
        self.assertNotIn('Built.', result.stdout)

    def test_it_says_built_when_both_pass(self):
        result = self.helper('build')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Built. Nothing was switched.', result.stdout)


if __name__ == '__main__':
    unittest.main()
