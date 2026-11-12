"""Run with: bin/test. Tests .github/scripts/plan-builds, which CI runs."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / '.github/scripts/plan-builds'

LINUX = 'x86_64-linux'
MAC = 'aarch64-darwin'
LIST = {
    LINUX: {'nelson@framework': '/nix/store/a-home.drv', 'nelson@temis': '/nix/store/b-home.drv',
            'nixos-framework': '/nix/store/c-eval.drv'},
    MAC: {'nelson.estevao@mac': '/nix/store/d-home.drv', 'darwin-mac': '/nix/store/e-eval.drv'},
}


class PlanBuildsTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='plan-builds test ')
        self.addCleanup(temp.cleanup)
        self.temp = Path(temp.name)
        self.summary = self.temp / 'summary.md'
        self.env = dict(os.environ, GITHUB_STEP_SUMMARY=str(self.summary))

    def run_script(self, *args, success=True):
        result = subprocess.run([str(SCRIPT), *args], env=self.env, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def save(self, checks, name='list.json'):
        path = self.temp / name
        path.write_text(checks if isinstance(checks, str) else json.dumps(checks))
        return str(path)

    def keys(self, checks):
        """{system: key} for a list."""
        out = self.run_script('keys', self.save(checks)).stdout
        return dict(line.split('=', 1) for line in out.splitlines())

    def matrix(self, forced, *found):
        out = self.run_script('matrix', self.save(LIST), forced, *found).stdout
        self.assertTrue(out.startswith('systems='), out)
        return json.loads(out.removeprefix('systems='))

    def test_a_system_the_runners_dont_know_stops_it(self):
        listing = dict(LIST, **{'aarch64-linux': {'nelson@pi': '/nix/store/f-home.drv'}})
        result = self.run_script('keys', self.save(listing), success=False)
        self.assertIn('aarch64-linux', result.stderr)

    def test_a_check_that_is_not_a_home_gives_no_key(self):
        listing = dict(LIST, **{LINUX: {'nixos-framework': '/nix/store/c-eval.drv',
                                        'lib-tests': '/nix/store/g-tests.drv'}})
        result = self.run_script('keys', self.save(listing), success=False)
        self.assertIn('no home configuration', result.stderr)

    def test_keys_are_stable_and_differ_per_system(self):
        first, second = self.keys(LIST), self.keys(LIST)
        self.assertEqual(first, second)
        self.assertEqual(sorted(first), [MAC, LINUX])
        self.assertNotEqual(first[LINUX], first[MAC])
        self.assertTrue(first[LINUX].startswith(f'green-{LINUX}-'))
        self.assertIn('```json', self.summary.read_text())

    def test_a_system_configuration_alone_moves_no_key(self):
        edited = copy.deepcopy(LIST)
        edited[LINUX]['nixos-framework'] = '/nix/store/z-eval.drv'
        edited[MAC]['darwin-mac'] = '/nix/store/y-eval.drv'
        self.assertEqual(self.keys(edited), self.keys(LIST))

    def test_a_home_change_moves_only_its_system_key(self):
        edited = copy.deepcopy(LIST)
        edited[LINUX]['nelson@temis'] = '/nix/store/z-home.drv'
        before, after = self.keys(LIST), self.keys(edited)
        self.assertNotEqual(before[LINUX], after[LINUX])
        self.assertEqual(before[MAC], after[MAC])

    def test_a_list_without_homes_for_a_system_fails(self):
        """A key over nothing would match forever, so it is an error."""
        cases = [({LINUX: LIST[LINUX]}, f'no home configuration for {MAC}'),
                 ({LINUX: {'nixos-framework': '/nix/store/c-eval.drv'}, MAC: LIST[MAC]},
                  f'no home configuration for {LINUX}'),
                 ('not JSON', 'parse error')]
        for checks, message in cases:
            with self.subTest(message):
                result = self.run_script('keys', self.save(checks), success=False)
                self.assertIn(message, result.stderr)
                self.assertNotIn(f'{LINUX}=', result.stdout)

    def test_matrix_builds_what_has_no_marker(self):
        keys = self.keys(LIST)
        self.assertEqual(self.matrix('false', keys[LINUX], keys[MAC]), [])
        self.assertIn(f'Already built: `{keys[LINUX]}`', self.summary.read_text())

        self.assertEqual(self.matrix('false', keys[LINUX], ''),
                         [{'system': MAC, 'os': 'macos-latest', 'key': keys[MAC]}])
        both = [{'system': MAC, 'os': 'macos-latest', 'key': keys[MAC]},
                {'system': LINUX, 'os': 'ubuntu-latest', 'key': keys[LINUX]}]
        self.assertEqual(self.matrix('false', '', ''), both)
        self.assertEqual(self.matrix('false'), both)
        # A marker under some other key does not count.
        self.assertEqual(self.matrix('false', 'green-x86_64-linux-old', ''), both)

    def test_forced_matrix_builds_everything(self):
        keys = self.keys(LIST)
        self.assertEqual(len(self.matrix('true', keys[LINUX], keys[MAC])), 2)

    def test_bad_arguments_fail(self):
        for args in ([], ['keys'], ['matrix', self.save(LIST)], ['matrix', self.save(LIST), 'yes'],
                     ['build', self.save(LIST)]):
            with self.subTest(args=args):
                result = self.run_script(*args, success=False)
                self.assertIn('plan-builds:', result.stderr)


if __name__ == '__main__':
    unittest.main()
