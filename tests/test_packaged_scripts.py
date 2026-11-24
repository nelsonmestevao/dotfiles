"""Run with: bin/test.

The xonsh and bash scripts that programs package: mode with theme, caffeine
and notifications (home/programs/mode/), and herd (home/programs/herd/). The
tests build the packages, as a home installs them, and run them against
stand-ins for the system tools they change: gsettings on Linux,
osascript, defaults and caffeinate on macOS, and herdr-app. Each stand-in
keeps what it was told in a folder of its own, so nothing on this machine
changes.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
MACOS = sys.platform == 'darwin'

STAND_INS = {
    # Keeps each key in its own file. Like the real one, it prints true and
    # false bare and other values in quotes.
    'gsettings': '''#!/usr/bin/env bash
key_file=$STATE/gsettings.$2.$3
case $1 in
  get) cat "$key_file" 2>/dev/null || echo false ;;
  set)
    case $4 in
      true | false) echo "$4" >"$key_file" ;;
      *) echo "'$4'" >"$key_file" ;;
    esac
    ;;
  *) exit 1 ;;
esac
''',
    # theme sends "... set dark mode to true" or "... to false".
    'osascript': '''#!/usr/bin/env bash
case "$*" in
  *"set dark mode to true"*) echo true >"$STATE/dark-mode" ;;
  *"set dark mode to false"*) echo false >"$STATE/dark-mode" ;;
  *) exit 1 ;;
esac
''',
    # Like the real one, it prints "Dark" in dark mode and fails in light
    # mode, where the setting does not exist.
    'defaults': '''#!/usr/bin/env bash
[[ "$*" == "read -g AppleInterfaceStyle" ]] || exit 1
[[ $(cat "$STATE/dark-mode" 2>/dev/null) == true ]] && echo Dark || exit 1
''',
    # Keeps nothing awake. It only lives until it is stopped, like the real one.
    'caffeinate': '''#!/usr/bin/env bash
sleep 600 &
trap 'kill $!' TERM
wait
''',
    # ls prints the spaces in $STATE/herdr-spaces.json, or none. do notes the
    # command in $STATE/herdr-commands.
    'herdr-app': '''#!/usr/bin/env bash
case $1 in
  ls) cat "$STATE/herdr-spaces.json" 2>/dev/null || echo '{"spaces": []}' ;;
  do) shift; echo "$*" >>"$STATE/herdr-commands"; echo '{}' ;;
  *) echo '{}' ;;
esac
''',
}


def build(*names):
    """The store path of each package, built as the flake builds it."""
    result = subprocess.run(['nix', 'build', '--no-link', '--print-out-paths', *(f'.#{n}' for n in names)],
                            cwd=ROOT, capture_output=True, text=True, check=True)
    return dict(zip(names, result.stdout.split()))


def setUpModule():
    global PACKAGES
    PACKAGES = build('mode', 'herd')


class PackagedScriptTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix='packaged-scripts-'))
        self.addCleanup(lambda: subprocess.run(['rm', '-rf', str(self.tmp)]))
        self.state = self.tmp / 'state'
        self.state.mkdir()
        stand_ins = self.tmp / 'stand-ins'
        stand_ins.mkdir()
        for name, script in STAND_INS.items():
            (stand_ins / name).write_text(script)
            (stand_ins / name).chmod(0o755)
        self.dotfiles = self.tmp / 'dotfiles'
        self.env = {**os.environ, 'STATE': str(self.state), 'DOTFILES': str(self.dotfiles),
                    'XDG_STATE_HOME': str(self.state),
                    'PATH': f'{stand_ins}:{os.environ["PATH"]}'}
        # A running caffeinate stand-in outlives the test unless it is stopped.
        self.addCleanup(lambda: self.run_it('caffeine', 'off'))

    def run_it(self, command, *args):
        """Runs a command of the packages. Gives back its output and errors together."""
        package = 'herd' if command == 'herd' else 'mode'
        result = subprocess.run([f'{PACKAGES[package]}/bin/{command}', *args], cwd=self.tmp,
                                env=self.env, capture_output=True, text=True)
        return result.stdout + result.stderr

    def write(self, path, text):
        (self.dotfiles / path).parent.mkdir(parents=True, exist_ok=True)
        (self.dotfiles / path).write_text(text)

    # ── Every command ────────────────────────────────────────────────────

    def test_each_command_shows_its_usage_by_name(self):
        for command in ('theme', 'caffeine', 'notifications', 'herd'):
            with self.subTest(command):
                self.assertIn(f'{command} [', self.run_it(command, '--help'))
                # A wrong option prints the usage first, with no xonsh
                # traceback hint above it.
                self.assertTrue(self.run_it(command, '--nope').startswith('Usage:'))

    # ── theme, caffeine, notifications ───────────────────────────────────

    def test_theme_switches_and_says_which(self):
        self.assertIn('light mode activated', self.run_it('theme', 'light'))
        self.assertEqual(self.run_it('theme', 'status').strip(), 'light')
        self.assertIn('dark mode activated', self.run_it('theme', 'dark'))
        self.assertEqual(self.run_it('theme', 'status').strip(), 'dark')

    def test_caffeine_switches_and_says_which(self):
        self.assertIn('caffeine is on', self.run_it('caffeine', 'on'))
        self.assertEqual(self.run_it('caffeine', 'status').strip(), 'on')
        self.assertIn('caffeine is off', self.run_it('caffeine', 'off'))
        self.assertEqual(self.run_it('caffeine', 'status').strip(), 'off')

    def test_notifications_switch_or_say_why_not(self):
        if MACOS:
            self.assertIn('cannot be switched on macOS', self.run_it('notifications', 'off'))
        else:
            self.assertIn('notifications are off', self.run_it('notifications', 'off'))
            self.assertEqual(self.run_it('notifications', 'status').strip(), 'off')

    # ── mode ─────────────────────────────────────────────────────────────

    def test_mode_switches_every_setting_and_back(self):
        self.write('home/programs/vscode/settings.json',
                   '{\n  "editor.fontSize": 18,\n  "terminal.integrated.fontSize": 16,\n}\n')
        self.write('home/programs/zed/settings.json',
                   '{\n  "buffer_font_size": 18,\n  "terminal": {\n    "font_size": 16,\n  },\n}\n')
        self.write('home/programs/ghostty/config', 'background-opacity = 0.6\nfont-size = 16\n')

        self.assertIn('USAGE', self.run_it('mode', '--help'))
        self.assertIn('mode v', self.run_it('mode', '--version'))
        self.assertIn('Changed to mode demo!', self.run_it('mode', 'demo'))
        self.assertTrue(self.run_it('mode', 'status').startswith('demo'))
        self.assertIn('"editor.fontSize": 32,', (self.dotfiles / 'home/programs/vscode/settings.json').read_text())
        self.assertIn('font-size = 26', (self.dotfiles / 'home/programs/ghostty/config').read_text())
        if MACOS:
            self.assertIn('notifications       -', self.run_it('mode', 'status'))

        chill = self.run_it('mode', 'chill')
        self.assertIn('Changed to mode chill!', chill)
        if MACOS:
            self.assertIn('notifications: not on macOS, left as they are', chill)
        self.assertTrue(self.run_it('mode', 'status').startswith('chill'))

    def test_mode_needs_the_checkout(self):
        del self.env['DOTFILES']
        self.assertIn('DOTFILES: must point to the dotfiles checkout', self.run_it('mode', 'status'))

    # ── herd ─────────────────────────────────────────────────────────────

    def test_herd_prune_closes_only_the_spaces_whose_folder_is_gone(self):
        # One space whose folder is gone, one whose folder is there, and one
        # on another machine, where this computer cannot look.
        (self.tmp / 'kept-space').mkdir()
        (self.state / 'herdr-spaces.json').write_text(json.dumps({'spaces': [
            {'id': 'sp1', 'name': 'gone', 'folder': str(self.tmp / 'no-such-folder'), 'machine': None},
            {'id': 'sp2', 'name': 'kept', 'folder': str(self.tmp / 'kept-space'), 'machine': None},
            {'id': 'sp3', 'name': 'far', 'folder': '/srv/no-such-folder', 'machine': 'vps'},
        ]}))
        commands = self.state / 'herdr-commands'

        self.assertIn('Would close space gone', self.run_it('herd', '--prune', '--dry-run'))
        self.assertFalse(commands.exists())

        self.assertIn('Closed space gone', self.run_it('herd', '--prune'))
        # Only the first space, and without Herdr asking first.
        self.assertEqual(commands.read_text(), 'space.close {"id": "sp1", "confirmed": true}\n')

        (self.state / 'herdr-spaces.json').unlink()
        self.assertIn('Nothing to close', self.run_it('herd', '--prune'))

    def test_herd_prune_takes_no_branch(self):
        self.assertTrue(self.run_it('herd', 'some-branch', '--prune').startswith('Usage:'))
        self.assertTrue(self.run_it('herd', 'some-branch', '--dry-run').startswith('Usage:'))


if __name__ == '__main__':
    unittest.main()
