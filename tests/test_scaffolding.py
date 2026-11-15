"""Run with: nix develop --command python3 -B -m unittest discover -s tests -v."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]


class ScaffoldingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='dotfiles test ')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1')
        for name in ('bin/new', 'bin/setup', 'scripts/scaffold.xsh', 'statix.toml'):
            self.write(name, (SOURCE / name).read_text())
        self.write('config/users.nix', '{\n  alice = { name = "Alice"; extraGroups = [ ]; };\n}\n')
        self.write('config/hosts.nix', '{\n  old = { roles = [ "desktop" ]; };\n}\n')
        self.write('home/users/alice.nix', '{ ... }: { }\n')
        self.write('flake.nix', '{ inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05"; }\n')
        self.run_command('nixfmt', 'config/users.nix', 'config/hosts.nix')
        self.run_command('git', 'init', '-q')
        self.run_command('git', 'add', '.')

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def run_command(self, *command, success=True):
        result = subprocess.run(command, cwd=self.root, env=self.env,
                                stdin=subprocess.DEVNULL, text=True, capture_output=True)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def script(self, script, *args, **kwargs):
        return self.run_command('xonsh', '--no-rc', f'bin/{script}', *args, **kwargs)

    def snapshot(self):
        return {str(p.relative_to(self.root)): p.read_bytes()
                for p in self.root.rglob('*') if p.is_file()
                and '.git' not in p.parts and '__pycache__' not in p.parts} | {
                    'INDEX': (self.root / '.git/index').read_bytes()}

    def fake(self, name, body):
        path = self.write(f'fake/{name}', '#!/bin/sh\n' + body + '\n')
        path.chmod(0o755)
        self.env['PATH'] = str(path.parent) + os.pathsep + os.environ['PATH']

    def assert_rejected_unchanged(self, script, *args):
        before = self.snapshot()
        result = self.script(script, *args, success=False)
        self.assertEqual(before, self.snapshot(), result.stdout + result.stderr)
        self.assertFalse((self.root / '.git/index.lock').exists())
        return result

    def host(self, *args, **kwargs):
        return self.script('setup', 'host', 'new-box', '--platform=nixos',
                           '--users=alice', *args, **kwargs)

    def test_invalid_names_leave_no_files(self):
        for name in ('../escape', 'a/b', 'bad name', '${oops}', 'let'):
            for script, kind in (('new', 'program'), ('setup', 'user'), ('setup', 'host')):
                with self.subTest(script=script, name=name):
                    result = self.assert_rejected_unchanged(script, kind, name)
                    self.assertIn('Invalid', result.stderr)

    def test_invalid_host_options_leave_no_files(self):
        cases = [
            ['--platform=nixos', '--system=aarch64-darwin', '--users=alice'],
            ['--platform=darwin', '--system=x86_64-linux', '--users=alice'],
            ['--platform=home', '--detect-hardware', '--users=alice'],
            ['--platform=nixos', '--users=nobody'],
            ['--platform=nixos', '--users=alice,alice'],
            ['--platform=nixos', '--users=alice', '--roles=old'],
            ['--platform=nixos', '--users=alice', '--roles=bad/role'],
        ]
        for args in cases:
            with self.subTest(args=args):
                self.assert_rejected_unchanged('setup', 'host', 'box', *args)

    def test_user_must_be_registered_and_have_a_module(self):
        self.write('home/users/orphan.nix', '{ ... }: { }\n')
        self.assert_rejected_unchanged('setup', 'host', 'box', '--platform=home', '--users=orphan')
        (self.root / 'home/users/alice.nix').unlink()
        self.assert_rejected_unchanged('setup', 'host', 'box', '--platform=home', '--users=alice')

    def test_display_name_escaping_and_existing_index_are_preserved(self):
        path = 'config/users.nix'
        staged = self.run_command('git', 'show', f':{path}').stdout
        original = '# unstaged comment\n' + (self.root / path).read_text()
        self.write(path, original)
        name = 'Renée "quoted" \\ path ${builtins.abort "oops"}\nNext\tline'
        self.script('setup', 'user', 'bob.smith', '--name=' + name, '--groups=')
        self.assertEqual(staged, self.run_command('git', 'show', f':{path}').stdout)
        self.assertTrue((self.root / path).read_text().startswith('# unstaged comment\n'))
        result = self.run_command('nix-instantiate', '--eval', '--strict', '--json', path)
        self.assertEqual(json.loads(result.stdout)['bob.smith']['name'], name)
        self.run_command('git', 'ls-files', '--error-unmatch', 'home/users/bob.smith.nix')

    def test_all_new_kinds_pass_lint_and_are_staged(self):
        for args in [('program', 'hello'), ('module', 'hello'),
                     ('module', 'hello', '--darwin'), ('extension', 'hello')]:
            self.script('new', *args)
        for name in ('home/programs/hello/hello.nix', 'system/modules/nixos/hello/hello.nix',
                     'system/modules/darwin/hello/hello.nix',
                     'home/programs/gnome/extensions/hello/hello.nix'):
            self.run_command('nixfmt', '--check', name)
            self.run_command('deadnix', '--fail', name)
            self.run_command('statix', 'check', name)
            self.run_command('git', 'ls-files', '--error-unmatch', name)
        self.assert_rejected_unchanged('new', 'program', 'hello')

    def test_home_only_host_does_not_create_system_files(self):
        self.script('setup', 'host', 'home-box', '--platform=home', '--users=alice')
        self.assertFalse((self.root / 'system').exists())
        self.run_command('nixfmt', '--check', 'config/hosts.nix')

    def test_hardware_is_a_stub_unless_explicit(self):
        self.fake('nixos-generate-config', 'echo hardware-must-not-run >&2; exit 9')
        result = self.host()
        self.assertIn('Incomplete hardware stub', result.stdout)
        self.assertIn('boot loader', result.stdout)
        for name in ('system/hosts/new-box.nix', 'system/hosts/new-box/hardware.nix'):
            self.run_command('nixfmt', '--check', name)
            self.run_command('deadnix', '--fail', name)
            self.run_command('statix', 'check', name)

    def test_explicit_hardware_failure_creates_nothing(self):
        self.fake('nixos-generate-config', 'exit 9')
        self.assert_rejected_unchanged('setup', 'host', 'box', '--platform=nixos',
                                       '--users=alice', '--detect-hardware')

    def test_explicit_hardware_success(self):
        self.fake('nixos-generate-config', "echo '{ ... }: { fileSystems.\"/\".device = \"/dev/example\"; }'")
        result = self.host('--detect-hardware')
        self.assertNotIn('Incomplete hardware stub', result.stdout)
        self.assertIn('/dev/example', (self.root / 'system/hosts/new-box/hardware.nix').read_text())

    def test_validation_failure_creates_nothing(self):
        self.fake('deadnix', 'exit 9')
        for script, kind, name in [('setup', 'user', 'bob'), ('new', 'program', 'hello')]:
            result = self.assert_rejected_unchanged(script, kind, name)
            self.assertIn('Command failed: deadnix', result.stderr)

    def test_formatter_failure_creates_nothing(self):
        self.fake('nixfmt', 'exit 9')
        result = self.assert_rejected_unchanged('setup', 'user', 'bob')
        self.assertIn('Command failed: nixfmt', result.stderr)

    def test_staging_failure_rolls_back_files_and_index(self):
        git = shutil.which('git')
        self.fake('git', f'if [ "$1" = add ]; then exit 9; fi\nexec "{git}" "$@"')
        result = self.assert_rejected_unchanged('setup', 'user', 'bob')
        self.assertIn('Command failed: git add', result.stderr)
        self.assertFalse((self.root / 'home/users/bob.nix').exists())
        self.assert_rejected_unchanged('new', 'program', 'hello')
        self.assertFalse((self.root / 'home/programs').exists())

    def test_darwin_template_and_state_version(self):
        source = self.root / 'darwin-source'
        self.write('darwin-source/modules/system/version.nix',
                   'maxStateVersion = mkOption { default = 7; };\n')
        self.fake('nix', f'echo "{source}"')
        self.script('setup', 'host', 'mac-box', '--platform=darwin', '--users=alice')
        self.run_command('deadnix', '--fail', 'system/hosts/mac-box.nix')
        self.run_command('statix', 'check', 'system/hosts/mac-box.nix')
        result = self.run_command('nix-instantiate', '--eval', '--strict', '--json', 'config/hosts.nix')
        self.assertEqual(json.loads(result.stdout)['mac-box']['darwinStateVersion'], 7)

    def test_invalid_nix_config_does_not_create_files(self):
        self.write('config/users.nix', '{ invalid = ; }\n')
        result = self.assert_rejected_unchanged('setup', 'user', 'bob')
        self.assertIn('Command failed: nix-instantiate', result.stderr)

    def test_existing_git_lock_is_respected(self):
        self.write('.git/index.lock', 'another git process')
        before = self.snapshot()
        self.script('setup', 'user', 'bob', success=False)
        self.assertEqual(before, self.snapshot())
        self.assertEqual((self.root / '.git/index.lock').read_text(), 'another git process')

    def test_symlink_destination_is_rejected(self):
        (self.root / 'home/programs').symlink_to(self.root / 'home/users')
        self.assert_rejected_unchanged('new', 'program', 'hello')


if __name__ == '__main__':
    unittest.main()
