"""Run with: bin/test.

bin/autoclean with a stand-in `nh` that records what it was asked, so
nothing is deleted.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin' / 'autoclean'


def keep_rule():
    """config/cleanup.nix, which NixOS's monthly cleanup reads too."""
    out = subprocess.run(['nix-instantiate', '--eval', '--strict', '--json', 'config/cleanup.nix'],
                         cwd=ROOT, text=True, capture_output=True, check=True).stdout
    return json.loads(out)


class AutocleanTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='autoclean test ')
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        self.log = self.dir / 'nh.log'
        self.stub('nh', f'echo "$@" > "{self.log}"')
        self.env = dict(os.environ, PATH=f'{self.dir}{os.pathsep}{os.environ["PATH"]}')

    def stub(self, name, body):
        path = self.dir / name
        path.write_text(f'#!/bin/sh\n{body}\n')
        path.chmod(0o755)

    def run_script(self, *args, env=None):
        return subprocess.run([str(SCRIPT), *args], env=env or self.env, text=True, capture_output=True)

    def asked(self):
        self.assertTrue(self.log.exists(), 'nh was never called')
        return self.log.read_text().split()

    def test_it_cleans_every_profile_by_the_shared_rule(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.asked(), ['clean', 'all', *keep_rule()])

    def test_it_leaves_project_gcroots_alone(self):
        self.assertIn('--no-gcroots', keep_rule())

    def test_a_dry_run_deletes_nothing(self):
        self.assertEqual(self.run_script('--dry-run').returncode, 0)
        self.assertEqual(self.asked(), ['clean', 'all', *keep_rule(), '--dry'])

    def test_without_the_rule_nothing_is_cleaned(self):
        # Without the rule nh would keep only one generation and delete the
        # project gcroots too, so a failed read must stop everything.
        self.stub('nix', 'echo "nix broke" >&2; exit 1')
        result = self.run_script()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.log.exists(), 'nh must not run without the rule')

    def test_help_prints_the_usage(self):
        result = self.run_script('--help')
        self.assertEqual(result.returncode, 0)
        self.assertIn('Usage: bin/autoclean [--dry-run]', result.stdout)
        self.assertFalse(self.log.exists())

    def test_anything_else_is_refused(self):
        for args in (['--dryrun'], [''], ['--dry-run', 'extra']):
            with self.subTest(args=args):
                result = self.run_script(*args)
                self.assertEqual(result.returncode, 1)
                self.assertIn('Usage:', result.stderr)
                self.assertFalse(self.log.exists(), 'nothing may run on a bad argument')

    def test_a_missing_nh_says_what_to_do(self):
        # Just what the script needs to start, wherever bash lives (on NixOS
        # it isn't in /bin), and no nh.
        bash = os.path.dirname(shutil.which('bash'))
        result = self.run_script(env=dict(self.env, PATH=f'{bash}{os.pathsep}/usr/bin{os.pathsep}/bin'))
        self.assertEqual(result.returncode, 1)
        self.assertIn('nh is missing', result.stderr)


if __name__ == '__main__':
    unittest.main()
