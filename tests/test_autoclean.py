"""Run with: bin/test.

bin/autoclean with a stand-in `nh` that records what it was asked, so
nothing is deleted.
"""
import json
import os
from pathlib import Path
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
        self.log = Path(temp.name) / 'nh.log'
        stub = Path(temp.name) / 'nh'
        stub.write_text(f'#!/bin/sh\necho "$@" > "{self.log}"\n')
        stub.chmod(0o755)
        self.env = dict(os.environ, PATH=f'{temp.name}{os.pathsep}{os.environ["PATH"]}')

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
        self.assertEqual(self.asked()[-1], '--dry')

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
        result = self.run_script(env=dict(self.env, PATH='/usr/bin:/bin'))
        self.assertEqual(result.returncode, 1)
        self.assertIn('nh is missing', result.stderr)


if __name__ == '__main__':
    unittest.main()
