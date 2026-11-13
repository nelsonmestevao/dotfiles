"""Run with: bin/test.

bin/rebuild and bin/build with a stand-in `nh` that records each call and
fails when told to, so nothing is built or switched, and a stand-in
`hostname`, so each test picks the machine it runs on. They check that each
host in config/hosts.nix gets its own configs, and what happens when a step
fails: the helper stops with one plain line, says what it left undone, and
runs nothing it shouldn't.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]

HOSTS = json.loads(subprocess.run(['nix-instantiate', '--eval', '--strict', '--json', 'config/hosts.nix'],
                                  cwd=ROOT, text=True, capture_output=True, check=True).stdout)


def host_with(platform):
    """A host in config/hosts.nix with this platform (None: a home only)."""
    return next((name for name, host in HOSTS.items() if host.get('platform') == platform), None)


# Most tests run on a NixOS host, as its first user.
HOST = host_with('nixos')
USER = HOSTS[HOST]['users'][0]
HOME = f'{USER}@{HOST}'
SYSTEM = f'nixosConfigurations.{HOST}'

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
        for name in ('bin/rebuild', 'bin/build', 'scripts/common.xsh', 'config/hosts.nix'):
            (self.repo / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(ROOT / name, self.repo / name)
        bin_dir = self.dir / 'stub'
        bin_dir.mkdir()
        for name, script in (('nh', NH), ('hostname', '#!/bin/sh\necho "$HOST"\n')):
            stub = bin_dir / name
            stub.write_text(script)
            stub.chmod(0o755)
        self.log = self.dir / 'nh.log'
        self.xonsh = shutil.which('xonsh')
        self.env = dict(os.environ, PATH=f'{bin_dir}{os.pathsep}{os.environ["PATH"]}',
                        LOG=str(self.log), FAIL='', INTERRUPT='', KILL='')
        self.env.pop('NIX_CONFIG', None)

    def helper(self, name, *args, host=HOST, user=USER, fail='', interrupt='', kill='',
               nix_config=None, without_nh=False):
        env = dict(self.env, HOST=host, USER=user, LOGNAME=user, FAIL=fail, INTERRUPT=interrupt, KILL=kill)
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
    def test_each_host_switches_its_own_configs(self):
        for host, data in HOSTS.items():
            for user in data['users']:
                with self.subTest(host=host, user=user):
                    self.log.unlink(missing_ok=True)
                    result = self.helper('rebuild', host=host, user=user)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    system = {'nixos': ['os switch . -H ' + host],
                              'darwin': ['darwin switch . -H ' + host]}.get(data.get('platform'), [])
                    self.assertEqual(self.calls(), system + [f'home switch . -c {user}@{host}'])

    def test_it_says_what_it_switches(self):
        result = self.helper('rebuild')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f'Switching {SYSTEM} and {HOME}', result.stdout)

    def test_a_failed_system_switch_leaves_the_home_alone(self):
        result = self.helper('rebuild', fail='os')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.calls(), [f'os switch . -H {HOST}'], 'the home must not be switched')
        self.assertIn(f'✗ nh os switch . -H {HOST} failed; {HOME} not switched.', result.stderr)
        self.assertNotIn('Traceback', result.stderr)
        self.assertNotIn('CalledProcessError', result.stderr)

    def test_a_failed_home_switch_says_so(self):
        result = self.helper('rebuild', 'home', fail='home')
        self.assertEqual(result.returncode, 1)
        self.assertIn(f'✗ nh home switch . -c {HOME} failed.', result.stderr)

    def test_it_keeps_what_nix_config_already_holds(self):
        result = self.helper('rebuild', 'home', nix_config='access-tokens = github.com=secret')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('access-tokens = github.com=secret', self.config())
        self.assertIn('extra-experimental-features = nix-command flakes', self.config())

    def test_ctrl_c_stops_it_and_says_what_was_left(self):
        result = self.helper('rebuild', interrupt='os')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.calls(), [f'os switch . -H {HOST}'])
        self.assertIn(f'Interrupted; {HOME} not switched.', result.stderr)

    def test_a_missing_nh_is_one_plain_line(self):
        result = self.helper('rebuild', without_nh=True)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stderr.strip().splitlines(),
                         ['✗ nh is missing. Run this from the repo, so it starts in the dev shell.'])
        self.assertEqual(self.calls(), [])

    def test_boot_starts_the_nixos_system_on_the_next_boot(self):
        result = self.helper('rebuild', '--boot')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [f'os boot . -H {HOST}', f'home switch . -c {HOME}'])

    def test_boot_without_a_nixos_system_is_refused(self):
        # A home, a Mac, and a host with only a home.
        cases = [(['home'], HOST), ([], host_with('darwin')), ([], host_with(None))]
        for command, host in cases:
            with self.subTest(command=command, host=host):
                if host is None:
                    self.skipTest('config/hosts.nix has no host of this kind')
                result = self.helper('rebuild', *command, '--boot', host=host, user=HOSTS[host]['users'][0])
                self.assertEqual(result.returncode, 1)
                self.assertIn('--boot is for a NixOS system only', result.stderr)
                self.assertEqual(self.calls(), [], 'nothing may be switched')

    def test_os_on_a_host_with_only_a_home_stops_before_nh(self):
        host = host_with(None)
        if host is None:
            self.skipTest('config/hosts.nix has no host with only a home')
        result = self.helper('rebuild', 'os', host=host, user=HOSTS[host]['users'][0])
        self.assertEqual(result.returncode, 1)
        self.assertIn(f'✗ {host} has no system config, only a home.', result.stderr)
        self.assertEqual(self.calls(), [])

    def test_an_unknown_host_names_the_known_ones(self):
        result = self.helper('rebuild', host='nowhere')
        self.assertEqual(result.returncode, 1)
        self.assertIn(f"config/hosts.nix has no host named nowhere. It has {', '.join(sorted(HOSTS))}.",
                      result.stderr)
        self.assertEqual(self.calls(), [])

    def test_a_user_without_a_home_there_stops_before_nh(self):
        result = self.helper('rebuild', user='someone')
        self.assertEqual(result.returncode, 1)
        self.assertIn(f'✗ {HOST} has no home for someone. config/hosts.nix lists its users. '
                      'Pass os for the system only.', result.stderr)
        self.assertEqual(self.calls(), [])


class BuildTests(HelperTests):
    def test_it_builds_both_even_when_the_first_fails(self):
        result = self.helper('build', fail='os')
        self.assertEqual(result.returncode, 1)
        self.assertEqual([call.split()[:2] for call in self.calls()], [['os', 'build'], ['home', 'build']])
        self.assertIn('✗ nh os build failed', result.stderr)
        self.assertNotIn('Built.', result.stdout)

    def test_it_builds_the_configs_of_this_host(self):
        result = self.helper('build')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call.split()[:5] for call in self.calls()],
                         [['os', 'build', '.', '-H', HOST], ['home', 'build', '.', '-c', HOME]])
        self.assertIn(f'Building {SYSTEM} and {HOME}', result.stdout)

    def test_a_host_with_only_a_home_builds_the_home(self):
        host = host_with(None)
        if host is None:
            self.skipTest('config/hosts.nix has no host with only a home')
        user = HOSTS[host]['users'][0]
        result = self.helper('build', host=host, user=user)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call.split()[:5] for call in self.calls()], [['home', 'build', '.', '-c', f'{user}@{host}']])

    def test_a_killed_build_is_a_failure_not_ctrl_c(self):
        result = self.helper('build', kill='os')
        self.assertEqual(result.returncode, 1)
        self.assertEqual([call.split()[0] for call in self.calls()], ['os', 'home'], 'the home build must still run')
        self.assertNotIn('Interrupted', result.stderr)

    def test_ctrl_c_stops_every_build(self):
        result = self.helper('build', interrupt='os')
        self.assertEqual(result.returncode, 1)
        self.assertEqual([call.split()[0] for call in self.calls()], ['os'], 'the home build must not start')
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
