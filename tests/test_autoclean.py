"""Run with: bin/test.

bin/autoclean with a stand-in `nix` that records what it was asked, so
nothing is deleted. It also checks that bin/autoclean and NixOS's monthly
cleanup keep the same generations.
"""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'bin' / 'autoclean'


class AutocleanTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='autoclean test ')
        self.addCleanup(temp.cleanup)
        self.log = Path(temp.name) / 'nix.log'
        stub = Path(temp.name) / 'nix'
        stub.write_text(f'#!/bin/sh\necho "$@" > "{self.log}"\n')
        stub.chmod(0o755)
        self.env = dict(os.environ, PATH=f'{temp.name}{os.pathsep}{os.environ["PATH"]}')

    def run_script(self, *args):
        return subprocess.run([str(SCRIPT), *args], env=self.env, text=True, capture_output=True)

    def asked(self):
        return self.log.read_text().split(' develop --command ')[1].split()

    def test_it_cleans_every_profile(self):
        self.assertEqual(self.run_script().returncode, 0)
        self.assertEqual(self.asked(), ['nh', 'clean', 'all', '--keep-since', '31d', '--keep', '3'])

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

    def test_it_keeps_what_nixos_keeps(self):
        script = re.search(r'^KEEP=\((.+)\)$', SCRIPT.read_text(), re.M).group(1)
        nixos = re.search(r'extraArgs = "(.+)";', (ROOT / 'system/nixos.nix').read_text()).group(1)
        self.assertEqual(script, nixos, 'bin/autoclean and system/nixos.nix keep different generations')


if __name__ == '__main__':
    unittest.main()
