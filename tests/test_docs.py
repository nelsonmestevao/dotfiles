"""Run with: bin/test.

The docs name files, scripts and hosts that change over time. These tests fail
when README.md, AGENTS.md or ROADMAP.md names one that is gone or leaves one
out, so the docs can't quietly fall behind the repo.
"""
import json
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
DOCS = ('README.md', 'AGENTS.md', 'ROADMAP.md')

# How each doc names a host's build, from its `platform` in config/hosts.nix.
BUILDS = {'nixos': 'NixOS', 'darwin': 'nix-darwin', None: 'Home Manager'}


def read(name):
    return (ROOT / name).read_text()


def hosts():
    """config/hosts.nix, as data."""
    out = subprocess.run(['nix-instantiate', '--eval', '--strict', '--json', 'config/hosts.nix'],
                         cwd=ROOT, text=True, capture_output=True, check=True).stdout
    return json.loads(out)


def host_rows(text):
    """{host: [cells]} from the first table whose header starts with Host."""
    after = text[text.index('| Host '):]
    rows = {}
    for line in after.splitlines()[1:]:
        if rows and not line.startswith('|'):
            break
        match = re.match(r'\| `([^`]+)` +\|(.*)\|$', line)
        if match:
            rows[match.group(1)] = [cell.strip() for cell in match.group(2).split('|')]
    return rows


class DocsTests(unittest.TestCase):
    def test_every_linked_file_exists(self):
        for doc in DOCS:
            for target in re.findall(r'\]\(([^)\s]+)\)', read(doc)):
                if re.match(r'[a-z]+:|#', target):
                    continue
                path = target.split('#')[0]
                with self.subTest(doc=doc, link=target):
                    self.assertTrue((ROOT / path).exists(), f'{doc} links to {path}, which is missing')

    def test_every_script_is_in_the_readme(self):
        readme = read('README.md')
        for script in sorted(p.name for p in (ROOT / 'bin').iterdir()):
            with self.subTest(script=script):
                self.assertIn(f'`bin/{script}', readme, f'README.md never mentions bin/{script}')

    def test_the_hosts_tables_match_the_data(self):
        data = hosts()
        for doc in ('README.md', 'AGENTS.md'):
            rows = host_rows(read(doc))
            with self.subTest(doc=doc):
                self.assertEqual(sorted(data), sorted(rows), f'the hosts table in {doc} lists other hosts')
            for name, host in data.items():
                cells = ' '.join(rows.get(name, []))
                with self.subTest(doc=doc, host=name):
                    self.assertIn(f'`{host["system"]}`', cells, f'{doc} gives {name} another system')
                    self.assertIn(BUILDS[host.get('platform')], cells, f'{doc} gives {name} another build')

    def test_the_dev_shell_loads_on_cd(self):
        # The README says direnv opens the dev shell on `cd`; that needs this file.
        envrc = ROOT / '.envrc'
        self.assertTrue(envrc.exists(), '.envrc is missing, so direnv opens no dev shell')
        self.assertEqual(envrc.read_text().strip(), 'use flake')


if __name__ == '__main__':
    unittest.main()
