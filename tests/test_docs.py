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


def git_files():
    """Every tracked file, and every folder that holds one. A link must point
    to one of these: an untracked file, or one whose name only matches on a
    Mac's case-blind disk, is broken on GitHub."""
    out = subprocess.run(['git', 'ls-files'], cwd=ROOT, text=True, capture_output=True, check=True).stdout
    files = set(out.splitlines())
    return files | {str(parent) for f in files for parent in Path(f).parents if str(parent) != '.'}


def without_blocks(text):
    """The text without fenced code blocks (indented or not, ``` or ~~~), where
    a link or a `#` line is only an example."""
    return re.sub(r'^[ \t]*(```|~~~).*?^[ \t]*\1', '', text, flags=re.M | re.S)


def prose(text):
    """The text without any code: blocks, and inline spans too."""
    return re.sub(r'`[^`\n]*`', '', without_blocks(text))


def links(text):
    """Every link target: inline `[x](target "title")`, reference `[x]: target`,
    and the `src` and `href` of the HTML in the README."""
    text = prose(text)
    inline = re.findall(r'\]\(<?([^)\s>]+)>?(?:\s+"[^"]*")?\)', text)
    reference = re.findall(r'^\s*\[[^\]]+\]:\s*<?(\S+?)>?(?:\s+"[^"]*")?\s*$', text, flags=re.M)
    html = re.findall(r'(?:src|srcset|href)="([^"]+)"', text)
    return inline + reference + html


def slug(heading):
    """GitHub's anchor for a heading: its words in lower case, links reduced
    to their text, anything but letters, digits, spaces and hyphens dropped,
    then each space a hyphen. "📄 License" is #-license."""
    heading = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', heading).rstrip('#').strip()
    return re.sub(r'[^\w\- ]', '', heading.lower()).replace(' ', '-')


def anchors(text):
    """The `#name` targets a doc has: its `id` attributes and its headings. A
    repeated heading gets -1, -2 and so on, as on GitHub."""
    ids = set(re.findall(r'\bid="([^"]+)"', text))
    seen = {}
    for heading in re.findall(r'^#+\s+(.+)$', without_blocks(text), flags=re.M):
        name = slug(heading)
        ids.add(f'{name}-{seen[name]}' if name in seen else name)
        seen[name] = seen.get(name, 0) + 1
    return ids


def hosts():
    """config/hosts.nix, as data."""
    out = subprocess.run(['nix-instantiate', '--eval', '--strict', '--json', 'config/hosts.nix'],
                         cwd=ROOT, text=True, capture_output=True, check=True).stdout
    return json.loads(out)


def cells(line):
    """A table row's cells, split on the pipes that aren't escaped."""
    return [cell.strip() for cell in re.split(r'(?<!\\)\|', line.strip())[1:-1]]


def table_rows(text, starts):
    """The rows of the first table whose header starts with `starts`, or None."""
    lines = without_blocks(text).splitlines()
    for i, line in enumerate(lines):
        if line.strip().startswith(starts):
            rows = []
            for row in lines[i + 2:]:
                if not row.strip().startswith('|'):
                    break
                rows.append(cells(row))
            return cells(line), rows
    return None


class DocsTests(unittest.TestCase):
    def test_every_link_points_to_something(self):
        files = git_files()
        for doc in DOCS:
            text = read(doc)
            for target in links(text):
                if re.match(r'[a-z]+:', target):
                    continue
                path, _, anchor = target.partition('#')
                path = path.lstrip('/').rstrip('/')
                with self.subTest(doc=doc, link=target):
                    if path:
                        self.assertTrue(path in files, f'{doc} links to {path}, which git does not track')
                    if anchor:
                        target_doc = path or doc
                        if target_doc.endswith('.md'):
                            self.assertTrue(anchor in anchors(read(target_doc)),
                                            f'{doc} links to {target_doc}#{anchor}, which it lacks')

    def test_every_script_is_in_the_scripts_table(self):
        table = table_rows(read('README.md'), '| Script')
        self.assertIsNotNone(table, 'README.md has no scripts table (a header starting with "| Script")')
        listed = {re.match(r'`bin/([^` ]+)', row[0]).group(1) for row in table[1] if row[0].startswith('`bin/')}
        scripts = {Path(f).name for f in git_files() if f.startswith('bin/') and '/' not in f[4:]}
        self.assertEqual(sorted(scripts - listed), [], 'these bin/ scripts are missing from the README table')
        self.assertEqual(sorted(listed - scripts), [], 'the README table lists bin/ scripts that are gone')

    def test_the_hosts_tables_match_the_data(self):
        data = hosts()
        for doc in ('README.md', 'AGENTS.md'):
            table = table_rows(read(doc), '| Host ')
            with self.subTest(doc=doc):
                self.assertIsNotNone(table, f'{doc} has no hosts table (a header starting with "| Host")')
            if table is None:
                continue
            header, rows = table
            named = [row[0].strip('`') for row in rows]
            with self.subTest(doc=doc):
                self.assertEqual(len(named), len(set(named)), f'{doc} lists a host twice')
                self.assertEqual(sorted(data), sorted(named), f'the hosts table in {doc} lists other hosts')
            for row in rows:
                name, columns = row[0].strip('`'), dict(zip(header[1:], row[1:]))
                host = data.get(name)
                if host is None:
                    continue
                build = BUILDS.get(host.get('platform'))
                with self.subTest(doc=doc, host=name):
                    self.assertIsNotNone(build, f'the docs have no name for platform {host.get("platform")!r}')
                    self.assertEqual(columns.get('System'), f'`{host["system"]}`', f'{doc} gives {name} another system')
                    self.assertTrue(columns.get('Build', '') == build or columns.get('Build', '').startswith(build + ' '),
                                    f'{doc} gives {name} another build')
                    if 'Roles' in columns:
                        listed = re.findall(r'`([^`]+)`', columns['Roles'])
                        self.assertEqual(sorted(listed), sorted(host.get('roles', [])),
                                         f'{doc} gives {name} other roles')

    def test_the_dev_shell_loads_on_cd(self):
        # The README says direnv opens the dev shell on `cd`; that needs this file.
        envrc = ROOT / '.envrc'
        self.assertTrue(envrc.exists(), '.envrc is missing, so direnv opens no dev shell')
        self.assertEqual(envrc.read_text().strip(), 'use flake')


if __name__ == '__main__':
    unittest.main()
