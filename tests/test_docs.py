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

# How the docs name a host's build, from its `platform` in config/hosts.nix.
BUILDS = {'nixos': 'NixOS', 'darwin': 'nix-darwin', None: 'Home Manager'}


def read(name):
    return (ROOT / name).read_text()


def outside_code(text):
    """The text without its fenced code blocks, where a link is only an example."""
    return re.sub(r'^```.*?^```', '', text, flags=re.M | re.S)


def links(text):
    """Every link target: inline `[x](target "title")` and reference `[x]: target`."""
    text = outside_code(text)
    inline = re.findall(r'\]\(<?([^)\s>]+)>?(?:\s+"[^"]*")?\)', text)
    reference = re.findall(r'^\s*\[[^\]]+\]:\s*<?(\S+?)>?(?:\s+"[^"]*")?\s*$', text, flags=re.M)
    return inline + reference


def anchors(text):
    """The `#name` targets a doc has: its `<a id>` tags and its headings."""
    ids = set(re.findall(r'<a id="([^"]+)"', text))
    for heading in re.findall(r'^#+\s+(.+)$', outside_code(text), flags=re.M):
        # GitHub's rule: lower case, drop what isn't a letter, digit, space or
        # hyphen, then each space becomes a hyphen. "📄 License" is #-license.
        ids.add(re.sub(r'[^\w\- ]', '', heading.lower()).replace(' ', '-'))
    return ids


def tracked(folder):
    """The files git tracks in `folder`: not .DS_Store, editor swap files and the like."""
    out = subprocess.run(['git', 'ls-files', '--', folder], cwd=ROOT,
                         text=True, capture_output=True, check=True).stdout
    return sorted(Path(line).name for line in out.splitlines())


def hosts():
    """config/hosts.nix, as data."""
    out = subprocess.run(['nix-instantiate', '--eval', '--strict', '--json', 'config/hosts.nix'],
                         cwd=ROOT, text=True, capture_output=True, check=True).stdout
    return json.loads(out)


def host_table(text):
    """{host: {column: cell}} from the first table whose header starts with Host."""
    lines = text[text.index('| Host '):].splitlines()
    cells = lambda line: [c.strip() for c in re.split(r'(?<!\\)\|', line.strip())[1:-1]]
    header = cells(lines[0])[1:]
    rows = {}
    for line in lines[2:]:
        if not line.strip().startswith('|'):
            break
        first, *rest = cells(line)
        rows[first.strip('`')] = dict(zip(header, rest))
    return rows


class DocsTests(unittest.TestCase):
    def test_every_link_points_to_something(self):
        for doc in DOCS:
            text = read(doc)
            for target in links(text):
                if re.match(r'[a-z]+:', target):
                    continue
                path, _, anchor = target.partition('#')
                with self.subTest(doc=doc, link=target):
                    if path:
                        self.assertTrue((ROOT / path.lstrip('/')).exists(),
                                        f'{doc} links to {path}, which is missing')
                    elif anchor:
                        self.assertIn(anchor, anchors(text), f'{doc} links to #{anchor}, which it lacks')

    def test_every_script_is_in_the_readme(self):
        readme = read('README.md')
        for script in tracked('bin'):
            with self.subTest(script=script):
                self.assertRegex(readme, rf'`bin/{re.escape(script)}[` ]',
                                 f'README.md never mentions bin/{script}')

    def test_the_hosts_tables_match_the_data(self):
        data = hosts()
        for doc in ('README.md', 'AGENTS.md'):
            rows = host_table(read(doc))
            with self.subTest(doc=doc):
                self.assertEqual(sorted(data), sorted(rows), f'the hosts table in {doc} lists other hosts')
            for name, host in data.items():
                row = rows.get(name, {})
                with self.subTest(doc=doc, host=name):
                    self.assertEqual(row.get('System'), f'`{host["system"]}`', f'{doc} gives {name} another system')
                    self.assertTrue(row.get('Build', '').startswith(BUILDS[host.get('platform')]),
                                    f'{doc} gives {name} another build')
                    if 'Roles' in row:
                        listed = re.findall(r'`([^`]+)`', row['Roles'])
                        self.assertEqual(sorted(listed), sorted(host.get('roles', [])),
                                         f'{doc} gives {name} other roles')

    def test_the_dev_shell_loads_on_cd(self):
        # The README says direnv opens the dev shell on `cd`; that needs this file.
        envrc = ROOT / '.envrc'
        self.assertTrue(envrc.exists(), '.envrc is missing, so direnv opens no dev shell')
        self.assertEqual(envrc.read_text().strip(), 'use flake')


if __name__ == '__main__':
    unittest.main()
