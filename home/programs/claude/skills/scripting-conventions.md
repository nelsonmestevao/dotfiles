---
name: scripting-conventions
description: scripting patterns and conventions for xonsh CLI scripts
---

# Scripting Conventions

If you're writing a CLI script for automation of some task, unless a different language is explicitly asked to use, choose xonsh by default.

## Shebang & Runtime

- Scripts use **nix-shell shebangs** for dependency management.
- **Project scripts** (e.g. `bin/` in repos): use `nix-shell` directly:
  ```
  #!/usr/bin/env nix-shell
  #! nix-shell -I nixpkgs=channel:nixos-25.11
  #! nix-shell -p gum python313 python313Packages.xonsh python313Packages.docopt
  #! nix-shell -i xonsh
  ```
- **Spell scripts** (personal, not shared): use the `spl` script to scaffold. Run `spl --help` first to see available options, then use it to create the initial script. Only start writing code after the template is generated. Always follow any conventions defined by the template.

## Docstring & CLI Parsing

- Always use `docopt` for argument parsing.
- The module docstring serves as the CLI help text, using `{program}` as a placeholder:
  ```python
  """
  Short description of what the script does.

  Usage:
    {program} ship new <name>...
    {program} ship <name> move <x> <y> [--speed=<kn>]
    {program} ship shoot <x> <y>
    {program} mine (set|remove) <x> <y> [--moored|--drifting]
    {program} -h | --help
    {program} --version

  Commands:
    ship      Ship subcommands description.
    mine      Mine subcommands description.

  Options:
    -h --help         Show this screen.
    -v --version      Show version.
    --speed=<kn>      Speed in knots [default: 10].
    --moored          Moored (anchored) mine.
    --drifting        Drifting mine.
  """
  ```
- The `docopt` call uses `__doc__.format(program=__file__)`.

## Script Structure (Top to Bottom)

1. Shebang lines (nix-shell for project scripts; for spells, use whatever `spl` generates)
2. Docstring with Usage/Commands/Options
3. Imports (`docopt`, `os`, `sys`, etc.)
4. `os.chdir(...)` to project root (for project scripts)
5. Color constants (tput-based, both `$VAR` xonsh-style and plain python)
6. Constants / configuration
7. Helper functions (get/set pattern for stateful operations)
8. `main(args)` function dispatching on `args` dict keys
9. `if __name__ == '__main__':` block with docopt parsing
10. `# vim: ft=<language`: use the language's filetype for syntax highlighting

## Color Constants

```python
# These are easy to use in bash commands.
$BLACK=$(tput setaf 0).strip()
$RED=$(tput setaf 1).strip()
$GREEN=$(tput setaf 2).strip()
$YELLOW=$(tput setaf 3).strip()
$BLUE=$(tput setaf 4).strip()
$MAGENTA=$(tput setaf 5).strip()
$CYAN=$(tput setaf 6).strip()
$WHITE=$(tput setaf 7).strip()
$PINK=$(tput setaf 13).strip()
$RESET=$(tput sgr0).strip()

# These are easy to use in python commands.
BLACK=$(tput setaf 0).strip()
RED=$(tput setaf 1).strip()
GREEN=$(tput setaf 2).strip()
YELLOW=$(tput setaf 3).strip()
BLUE=$(tput setaf 4).strip()
MAGENTA=$(tput setaf 5).strip()
CYAN=$(tput setaf 6).strip()
WHITE=$(tput setaf 7).strip()
PINK=$(tput setaf 13).strip()
RESET=$(tput sgr0).strip()
```

## Patterns

- **Success feedback**: Print confirmation with green checkmark (`✓`).
- **Error feedback**: Print with red cross (`✗`) and `sys.exit(1)`.
- **match/case**: Use Python 3.10+ structural pattern matching for dispatching.
- **Xonsh subprocess calls**: Use bare commands (not `subprocess.run`) since xonsh supports it natively.
- **Improve UX with gum**: Anytime you want a polish experience, use `gum` commands. Learn about all the options with `gum --help <subcommand>`

## File Placement

| Context | Location |
|---------|----------|
| Project utility scripts | `bin/` at project root |
| Personal spell scripts | Use `spl` to create (run `spl --help` first) |

## Version Strings

- Project scripts: `version=f'{os.path.basename(__file__)} script version 1.0'`
- Spell scripts: follow the template conventions from `spl`
