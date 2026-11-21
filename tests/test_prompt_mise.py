"""Run with: bin/test.

The prompt's mise segment (home/programs/zsh/prompt-mise.zsh) in a bare zsh.
A stand-in `mise` answers with the tools a test gives it and notes each time
it is asked, and a stand-in `p10k` writes down each segment it is told to
draw. They check what the segment draws for a tool, and how seldom it asks.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SEGMENT = ROOT / 'home/programs/zsh/prompt-mise.zsh'

# Answers the one question the segment asks, and counts the askings.
MISE = '''#!/bin/sh
echo asked >> "$ASKED"
[ "$*" = "ls --current --local --installed --json" ] || exit 2
cat "$ANSWER"
'''

# Writes down what it is told to draw, like `p10k segment` would draw it.
P10K = 'function p10k() { print -r -- "$*" >> $DRAWN }'


class PromptMiseTest(unittest.TestCase):
    def setUp(self):
        self.home = Path(tempfile.mkdtemp(prefix='prompt-mise-'))
        self.addCleanup(lambda: subprocess.run(['rm', '-rf', str(self.home)]))
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        self.drawn = self.home / 'drawn'
        self.asked = self.home / 'asked'
        self.answer = self.home / 'answer.json'

    def install_mise(self):
        mise = self.bin / 'mise'
        mise.write_text(MISE)
        mise.chmod(0o755)

    def prompt(self, tools, script='prompt_mise', before=''):
        """Runs `script` in a zsh that has the segment, with mise answering
        `tools`. Gives back what the zsh printed."""
        self.answer.write_text(json.dumps({tool: [{'version': version}] for tool, version in tools.items()}))
        env = dict(os.environ,
                   PATH=f"{self.bin}{os.pathsep}{os.environ['PATH']}",
                   ASKED=str(self.asked), ANSWER=str(self.answer), DRAWN=str(self.drawn))
        result = subprocess.run(['zsh', '-f', '-c', f'{P10K}\n{before}\nsource {SEGMENT}\n{script}'],
                                cwd=self.home, env=env, capture_output=True, text=True)
        self.assertEqual(result.stderr, '')
        self.assertEqual(result.returncode, 0)
        return result.stdout

    def segments(self):
        return self.drawn.read_text().splitlines() if self.drawn.exists() else []

    def times_asked(self):
        return len(self.asked.read_text().splitlines()) if self.asked.exists() else 0

    def test_a_known_tool_gets_its_icon_and_its_style(self):
        self.install_mise()
        self.prompt({'elixir': '1.18.4-otp-27', 'erlang': '27.3.4'})
        self.assertEqual(self.segments(), [
            'segment -s ELIXIR -r -i ELIXIR_ICON -t 1.18.4-otp-27',
            'segment -s ERLANG -r -i ERLANG_ICON -t 27.3.4',
        ])

    def test_a_tool_goes_by_the_name_asdf_has_for_it(self):
        # Powerlevel10k's icons and colors are named after asdf's plugins.
        self.install_mise()
        self.prompt({'node': '24.22.1', 'go': '1.26.0', 'dotnet': '9.0.1'})
        self.assertEqual(self.segments(), [
            'segment -s NODEJS -r -i NODEJS_ICON -t 24.22.1',
            'segment -s GOLANG -r -i GOLANG_ICON -t 1.26.0',
            'segment -s DOTNET_CORE -r -i DOTNET_CORE_ICON -t 9.0.1',
        ])

    def test_a_tool_with_no_icon_shows_by_its_name(self):
        self.install_mise()
        self.prompt({'kubectl': '1.34.9'})
        self.assertEqual(self.segments(), ['segment -t kubectl 1.34.9'])

    def test_a_folder_that_sets_no_tool_draws_nothing(self):
        self.install_mise()
        self.prompt({})
        self.assertEqual(self.segments(), [])

    def test_without_mise_it_draws_nothing_and_says_nothing(self):
        self.prompt({'elixir': '1.18.4'})
        self.assertEqual(self.segments(), [])
        self.assertEqual(self.times_asked(), 0)

    def test_mise_is_asked_once_for_a_folder_and_again_in_the_next(self):
        self.install_mise()
        self.prompt({'elixir': '1.18.4'}, script='prompt_mise; prompt_mise; prompt_mise')
        self.assertEqual(self.times_asked(), 1)
        self.assertEqual(len(self.segments()), 3)

        self.asked.unlink()
        self.prompt({'elixir': '1.18.4'}, script='prompt_mise; cd /; prompt_mise; prompt_mise')
        self.assertEqual(self.times_asked(), 2)

    def test_mise_is_asked_again_when_path_changes(self):
        # mise makes a tool the current one by putting it on PATH.
        self.install_mise()
        self.prompt({'elixir': '1.18.4'}, script='prompt_mise; path+=(/somewhere/new); prompt_mise')
        self.assertEqual(self.times_asked(), 2)

    def test_a_percent_sign_in_a_version_is_not_a_prompt_code(self):
        self.install_mise()
        self.prompt({'elixir': '1.18%F'})
        self.assertEqual(self.segments(), ['segment -s ELIXIR -r -i ELIXIR_ICON -t 1.18%%F'])

    def test_the_colors_are_the_ones_set_for_asdf(self):
        self.install_mise()
        out = self.prompt({}, before='typeset -g POWERLEVEL9K_ASDF_BACKGROUND=7 POWERLEVEL9K_ASDF_ELIXIR_BACKGROUND=5 '
                                     'POWERLEVEL9K_ASDF_ELIXIR_FOREGROUND=0 POWERLEVEL9K_ASDF_SHOW_SYSTEM=true',
                          script='print -r -- $POWERLEVEL9K_MISE_BACKGROUND $POWERLEVEL9K_MISE_ELIXIR_BACKGROUND '
                                 '$POWERLEVEL9K_MISE_ELIXIR_FOREGROUND ${+POWERLEVEL9K_MISE_SHOW_SYSTEM}')
        # The colors come over. The asdf segment's other settings don't.
        self.assertEqual(out.split(), ['7', '5', '0', '0'])


if __name__ == '__main__':
    unittest.main()
