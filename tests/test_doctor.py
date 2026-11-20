"""Run with: bin/test.

bin/doctor in a throwaway home, with a stand-in `rclone` that lists the
remotes a test gives it and a stand-in `ssh-add` with no keys. They check
that it finds what is there, names what is missing and how to make it, and
only fails for what a machine really needs.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]

# Lists the remotes in $REMOTES, one per line, like `rclone listremotes`.
RCLONE = '''#!/bin/sh
[ "$1" = listremotes ] || exit 2
for remote in $REMOTES; do echo "$remote:"; done
'''

# An SSH agent that holds no key.
SSH_ADD = '''#!/bin/sh
echo "The agent has no identities." >&2
exit 1
'''

KEY = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleExampleExampleExampleExampleExampleExam'


class DoctorTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix='doctor test ')
        self.addCleanup(temp.cleanup)
        self.dir = Path(temp.name)
        self.repo = self.dir / 'repo'
        for name in ('bin/doctor', 'scripts/common.xsh'):
            (self.repo / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(ROOT / name, self.repo / name)
        self.home = self.dir / 'home'
        self.home.mkdir()
        stubs = self.dir / 'stub'
        stubs.mkdir()
        for name, script in (('rclone', RCLONE), ('ssh-add', SSH_ADD)):
            stub = stubs / name
            stub.write_text(script)
            stub.chmod(0o755)
        self.needs = self.dir / 'made-by-hand.json'
        self.env = dict(os.environ, HOME=str(self.home), REMOTES='',
                        PATH=f'{stubs}{os.pathsep}{os.environ["PATH"]}',
                        DOTFILES_MADE_BY_HAND=str(self.needs))
        # The user's own git config must come from the throwaway home only.
        for name in ('XDG_CONFIG_HOME', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_SYSTEM'):
            self.env.pop(name, None)
        self.env['GIT_CONFIG_NOSYSTEM'] = '1'

    def doctor(self, remotes=''):
        return subprocess.run([shutil.which('xonsh'), '--no-rc', 'bin/doctor'], cwd=self.repo,
                              env=dict(self.env, REMOTES=remotes), stdin=subprocess.DEVNULL,
                              text=True, capture_output=True)

    def system_needs(self, files=(), remotes=()):
        self.needs.write_text(json.dumps({
            'files': [{'path': str(self.home / name), 'what': 'A secret.', 'how': f'Make {name} by hand.'}
                      for name in files],
            'rcloneRemotes': list(remotes),
        }))

    def git_config(self, text):
        (self.home / '.gitconfig').write_text(text)

    def test_a_machine_that_needs_nothing_passes(self):
        result = self.doctor()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Nothing is missing', result.stdout)
        # ~/.zshenv.local is optional: it is named, but it is no failure.
        self.assertIn('~/.zshenv.local is not there', result.stdout)

    def test_a_missing_file_is_named_with_how_to_make_it(self):
        self.system_needs(files=['restic.pw'])
        result = self.doctor()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn(f'{self.home}/restic.pw is missing. A secret.', result.stdout)
        self.assertIn('Make restic.pw by hand.', result.stdout)
        self.assertIn('1 missing', result.stderr)

    def test_a_missing_remote_is_named(self):
        self.system_needs(remotes=['mega', 'gdrive'])
        result = self.doctor(remotes='mega')
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('rclone remote mega', result.stdout)
        self.assertIn('rclone has no remote named gdrive', result.stdout)
        self.assertIn('rclone config', result.stdout)

    def test_everything_in_place_passes(self):
        self.system_needs(files=['restic.pw'], remotes=['mega', 'gdrive'])
        (self.home / 'restic.pw').write_text('secret\n')
        (self.home / '.zshenv.local').write_text('')
        result = self.doctor(remotes='gdrive mega')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('Nothing is missing', result.stdout)
        self.assertNotIn('✗', result.stdout)
        self.assertNotIn('!', result.stdout)

    def test_every_missing_thing_is_counted(self):
        self.system_needs(files=['restic.pw', 'other.pw'], remotes=['mega'])
        result = self.doctor()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('3 missing', result.stderr)

    def test_a_signing_key_given_as_a_path_must_exist(self):
        self.git_config('[user]\n\tsigningkey = ~/.ssh/id_ed25519.pub\n')
        result = self.doctor()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('~/.ssh/id_ed25519.pub, the key that signs your commits, is missing', result.stdout)

        (self.home / '.ssh').mkdir()
        (self.home / '.ssh/id_ed25519.pub').write_text(KEY + ' me@host\n')
        result = self.doctor()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('~/.ssh/id_ed25519.pub signs your commits', result.stdout)

    def test_a_signing_key_given_as_the_key_must_be_on_the_machine(self):
        self.git_config(f'[user]\n\tsigningkey = {KEY}\n')
        result = self.doctor()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('The key that signs your commits is not on this machine', result.stdout)

        (self.home / '.ssh').mkdir()
        (self.home / '.ssh/work.pub').write_text(KEY + ' another comment\n')
        result = self.doctor()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('The key that signs your commits is on this machine', result.stdout)

    def test_a_signing_program_must_be_installed(self):
        program = self.dir / 'op-ssh-sign'
        self.git_config(f'[user]\n\tsigningkey = {KEY}\n[gpg "ssh"]\n\tprogram = {program}\n')
        result = self.doctor()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn(f'{program}, which signs your commits, is not installed', result.stdout)

        program.write_text('#!/bin/sh\n')
        result = self.doctor()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f'{program} signs your commits', result.stdout)

if __name__ == '__main__':
    unittest.main()
