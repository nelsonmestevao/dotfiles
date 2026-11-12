"""Shared validation and file transaction for bin/new and bin/setup."""
import json
import os
from pathlib import Path
import re
import shutil
import tempfile


def require(value, message):
    if not value:
        raise ValueError(message)
    return value


def checked(command):
    result = !(@(command))
    require(result.returncode == 0,
            f"Command failed: {' '.join(command)}\n{result.out or ''}{result.err or ''}".rstrip())
    return result.out.strip()


def validate_name(name, kind):
    pattern = r'[a-z][a-z0-9_-]*' if kind == 'module' else r'[A-Za-z0-9_][A-Za-z0-9_.-]*'
    require(re.fullmatch(pattern, name) and '..' not in name,
            f"Invalid {kind} name {name!r}: use letters, digits, underscores or hyphens"
            + ("." if kind == 'module' else "; dots are also allowed."))
    require(name not in {'if', 'then', 'else', 'assert', 'with', 'let', 'in', 'rec', 'inherit', 'or',
                        'true', 'false', 'null'},
            f"Invalid {kind} name {name!r}: reserved Nix keyword.")
    return name


def nix_string(value):
    require(all(ord(c) >= 32 or c in '\n\r\t' for c in value),
            'Nix strings cannot contain control characters other than newline, tab or carriage return.')
    return '"' + (value.replace('\\', '\\\\').replace('"', '\\"')
                  .replace('${', '\\${').replace('\n', '\\n')
                  .replace('\r', '\\r').replace('\t', '\\t')) + '"'


def nix_key(name):
    return name if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_-]*', name) else nix_string(name)


def nix_value(value):
    if isinstance(value, str):
        return nix_string(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, list):
        return '[ ' + ' '.join(nix_value(v) for v in value) + ' ]'
    return '{ ' + ' '.join(f'{nix_key(k)} = {nix_value(v)};' for k, v in value.items()) + ' }'


def read_config(path):
    value = json.loads(checked(['nix-instantiate', '--eval', '--strict', '--json', path]))
    require(isinstance(value, dict), f'{path} must contain an attribute set.')
    return value


def insert_entry(source, name, entry):
    # These data files use a standalone opening brace. Refuse an unfamiliar
    # layout instead of guessing; evaluation below also verifies the result.
    openings = list(re.finditer(r'^\{[ \t]*$', source, re.M))
    require(len(openings) == 1, 'Expected one standalone opening brace in config file.')
    offset = openings[0].end()
    with tempfile.TemporaryDirectory(prefix='dotfiles-entry-') as scratch:
        draft = Path(scratch) / 'entry.nix'
        draft.write_text('{\n' + nix_key(name) + ' = ' + nix_value(entry) + ';\n}\n')
        checked(['nixfmt', str(draft)])
        block = '\n'.join(draft.read_text().splitlines()[1:-1])
    return source[:offset] + '\n' + block + source[offset:]


def apply_files(files, originals=None, expected=None):
    """Validate in scratch space, then publish; preserve existing index entries.

    Existing config text is left as supplied, so unrelated formatting edits
    remain intact. Only new files are staged. Caught write/staging failures
    restore the working tree; the real index changes only after all writes.
    """
    originals = originals or {}
    expected = expected or {}
    new = [name for name in files if name not in originals]
    for name in files:
        target = Path(name)
        require(not target.is_symlink() and all(not p.is_symlink() for p in target.parents),
                f'Refusing symlink destination: {name}')
        if name in originals:
            require(target.read_text() == originals[name], f'{name} changed during setup; retry.')
        else:
            require(not target.exists(), f'{name} already exists.')

    with tempfile.TemporaryDirectory(prefix='dotfiles-scaffold-') as scratch:
        root = Path(scratch)
        prepared = {}
        for name, content in files.items():
            draft = root / name
            draft.parent.mkdir(parents=True, exist_ok=True)
            draft.write_text(content)
            checked(['nixfmt', str(draft)])
            checked(['deadnix', '--fail', str(draft)])
            # Statix discovers its config from the working directory.
            checked(['statix', 'check', str(draft)])
            if name in expected:
                require(read_config(str(draft)) == expected[name],
                        f'{name}: rendered configuration does not match the requested change.')
            prepared[name] = content if name in originals else draft.read_text()

        index = Path(checked(['git', 'rev-parse', '--git-path', 'index'])).absolute()
        lock = Path(str(index) + '.lock')
        # Respect Git's index lock, including when the repo is a worktree.
        with lock.open('xb'):
            pass
        written = []
        directories = []
        try:
            alternate = root / 'index'
            if index.exists():
                shutil.copyfile(index, alternate)
            for name, content in prepared.items():
                target = Path(name)
                if name in originals:
                    require(target.read_text() == originals[name], f'{name} changed during setup; retry.')
                else:
                    require(not target.exists(), f'{name} appeared during setup; retry.')
                missing = [p for p in target.parents if not p.exists()]
                for directory in reversed(missing):
                    directory.mkdir()
                    directories.append(directory)
                with target.open('w' if name in originals else 'x') as output:
                    written.append(name)
                    output.write(content)
            with __xonsh__.env.swap(GIT_INDEX_FILE=str(alternate)):
                if not index.exists():
                    checked(['git', 'read-tree', '--empty'])
                if new:
                    checked(['git', 'add', '--', *new])
            shutil.copyfile(alternate, lock)
            os.replace(lock, index)
        except BaseException:
            for name in reversed(written):
                if name in originals:
                    Path(name).write_text(originals[name])
                else:
                    Path(name).unlink(missing_ok=True)
            for directory in reversed(directories):
                directory.rmdir()
            raise
        finally:
            lock.unlink(missing_ok=True)

# vim: ft=xonsh
