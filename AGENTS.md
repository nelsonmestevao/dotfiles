# AGENTS.md

Nix flake for my machines: NixOS, nix-darwin (macOS), and standalone Home
Manager. The README explains the design. This file covers what an agent needs
to work here safely.

## Layout

- `config/hosts.nix`, `config/users.nix`, `config/overlays.nix`: the data.
  Hosts, users, and the overlays every config shares.
- `lib/`: turns `config/` into the flake outputs. `lib/schema.nix` checks the
  data first; a new host or user field needs an option there. `lib/checks.nix`
  holds the checks. `flake.nix` only declares inputs, checks, and the dev
  shell.
- `home/programs/<name>/<name>.nix`: one Home Manager program per folder,
  wrapped by `home/lib/mkHomeModule.nix`. It adds the
  `dotfiles.programs.<name>.enable` option and the `mkSymlink` helper. A
  module adds its own settings with `options.<setting>`.
- `home/users/<username>.nix`: which programs a user gets, and where.
- `system/modules/{nixos,darwin}/<name>/<name>.nix`: system modules, with
  `dotfiles.modules.<name>.enable`.
- `system/hosts/<hostname>.nix`: which modules a host gets, plus settings only
  that host needs (boot loader, firewall, keyboard layout).
- `bin/`: helper scripts. Each one runs inside the flake's dev shell.
- `scripts/`: shared libraries imported by the helpers in `bin/`.
- `.github/scripts/`: scripts only CI runs, next to the workflow that calls
  them. They run outside the dev shell, so they need only bash and jq.
- `tests/lib.nix`: tests for the helpers in `lib/` and `home/lib/`, against
  `tests/fixtures/`. `bin/check --eval` runs them. Change a helper, add a case.

## Hosts

| Host                    | Build        | System           |
| ----------------------- | ------------ | ---------------- |
| `framework`             | NixOS        | `x86_64-linux`   |
| `temis`                 | NixOS        | `x86_64-linux`   |
| `thinkpad`              | Home Manager | `x86_64-linux`   |
| `Remote-Nelson-Estevao` | nix-darwin   | `aarch64-darwin` |

An agent may run on any of these machines, so run `hostname -s` first. A command
that only works on another OS (a Mac build on Linux, `nixos-rebuild` on the
Mac) can't run there: ask me to run it and paste the output back.

## Rules

- **Flakes only see tracked files.** `git add` a new file before you build or
  evaluate, or Nix acts as if it doesn't exist.
- **Host choices go in user and host files, not in modules.** Use
  `enableFor` / `disableFor` (or `valueFor` to pick a value) with roles
  (`desktop`, `server`, `linux`, `darwin`) or host names in
  `home/users/*.nix`. A module should not check the host name or the user
  name.
- **A value that differs per user or host is a setting.** The module declares
  it with `options.<setting>` next to its config and reads it from
  `config.dotfiles.programs.<name>.<setting>`. The user file sets it (the git
  signing key works this way: `valueFor` names each host, and a host left out
  signs nothing).
- **A module returns a plain attribute set.** Put `lib.mkIf` on single values
  inside it. A body wrapped whole in `lib.mkIf` or `lib.mkMerge` is an error
  that names the module. A body that is `if config.… then … else …` loops
  forever. A setting can't be named `enable`; the wrapper owns it.
- **Prefer roles over host names.** A new desktop should need one line in
  `config/hosts.nix`, not edits to user files. Naming a host the user has no
  home on is an error.
- **Mark one-OS modules** with `platforms = [ "linux" ]` or `[ "darwin" ]`
  next to the config. Turning one on for the wrong OS then fails with a clear
  message.
- **Link config files with `mkSymlink "path"`.** The file must exist in the
  program's folder, or the build fails. These are real links into this repo,
  so an edit takes effect on my live machine right away, with no rebuild.
- **Some apps write back through the link** (Claude's `settings.json`, Herdr's
  `islands.json`). A diff in those files may come from the app, not from me.
  Ask before you revert it.
- **Herdr mods are copied, not linked.** Edit them in
  `home/programs/herdr-app/` and run `bin/rebuild home`. Edits in
  `~/.config/herdr-app` get overwritten.
- **New flake input:** add it to `inputs` in `flake.nix` and its overlay to
  `config/overlays.nix`. If the overlay reuses a nixpkgs package name, give it
  a new one (like `orca-app`).
- **A package built here lives next to its program** as `package.nix`. It
  becomes a flake output on its own, named after its folder
  (`nix build .#<name>`), and says where it runs with `meta.platforms`.
- **Wrap the override someone would delete** in
  `pkgs.expiry.untilUpstreamHas` or `pkgs.expiry.expiresWhen`
  (`lib/expiry.nix`), so it warns once the fix it waits for is out. An override
  inside a package file that goes away with it needs nothing. A package
  patched in `config/overlays.nix` is also listed in `lib/packages.nix`.
- **Never change `stateVersion` or `darwinStateVersion`** on an existing host.
- **New program, module, user, or host:** use `bin/new` or `bin/setup`. Don't
  write the files by hand. `bin/new module <name> --darwin` makes a nix-darwin
  module. `bin/setup` prompts in a terminal; pass its answers as flags
  instead (see `bin/setup --help`).

## Check your work

Run these before you say a change works:

```shell
bin/lint          # deadnix, statix, nixfmt --check (CI runs it first)
bin/format        # fixes nixfmt errors
bin/test          # the helper scripts' tests and the docs check (CI too)
bin/check --eval  # evaluates every config, Mac ones too; builds nothing
bin/check --same  # shows which configs your change builds differently
```

Run `bin/test` when you touch `bin/`, `scripts/`, `tests/`, `.github/`, the
docs, or `config/hosts.nix`.

`bin/check --eval` takes about a minute. It catches option and assertion
errors in all seven configs, NixOS, nix-darwin and Home Manager, without a
full build. The Mac configs evaluate fine from Linux, and the Linux ones from
the Mac. Evaluating a config does not test that it activates on the other OS.

`bin/check --same` compares the derivation of every config with the last
commit, or with `<rev>` in `bin/check --same <rev>`. A refactor must show
every config as "same". A change that is meant to alter a config should alter
only the configs you expect. Add `--why` to see what differs. `git add` new
files first, or the flake can't see them; the command lists the untracked
files it found.

To check one config while you work, evaluate just that one:

```shell
nix eval --raw '.#homeConfigurations."nelson@framework".activationPackage.drvPath'
```

`bin/check` with no flag evaluates every config on every system, then builds
the checks of this machine's system, as each CI runner does for its own. It
is slow. Use it for changes to `lib/` or `flake.nix`. `bin/check
--all-systems` also builds the other OS and needs a builder for it.

To prove a change really builds on this machine, run `bin/build` (or
`bin/build home`). It builds the configs and prints what would change, but
never switches and needs no `sudo`, so you don't need to ask first.

## Ask first

- `bin/rebuild`: switches my live system or home and may need `sudo`.
- `bin/autoclean`: deletes old generations with `sudo`.
- `bin/update`: moves every flake input.
- Anything with `sudo`.
- Any `git push`, and any commit unless I asked for one.

`.claude/settings.json` makes Claude Code ask before these, and before the
`nh`, `nixos-rebuild` and `home-manager` commands that do the same things.
Change this list and that file together.

## Code style

- Nix: `nixfmt`, two-space indent. `statix.toml` turns off `empty_pattern`
  and `repeated_keys` on purpose. Don't "fix" those.
- Comments say why, in plain words. Section breaks look like
  `# ── Name ─────`.
- New scripts in `bin/` are xonsh with docopt. (`autoclean`, `format`,
  `lint` and `test` are short bash wrappers.) Copy the shebang, the `Usage:` block, and
  the `# vim: ft=xonsh` modeline from a xonsh script like `bin/check`. Tools a
  script needs go in the dev shell in `flake.nix`. Full rules:
  `home/programs/claude/skills/scripting-conventions/SKILL.md`.
- When you change how something works, update `README.md` in the same commit.
  It documents the helpers, the host and user fields, and the scripts table.

## Commits

- Subject: `[scope]: lowercase imperative summary`, where the scope is the
  program or area (`[zed]`, `[lib]`, `[ci]`, `[hosts]`).
- Body: short prose on what changed and why.
- Input upgrades come from `bin/update --save`, which writes the
  `chore: upgrade ...` commit. Don't write those by hand.
- No `Claude-Session` or other agent trailers.

## Writing

Plain language in docs, comments, and commit messages: short sentences, active
voice, common words, no filler.
