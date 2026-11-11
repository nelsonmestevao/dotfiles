# AGENTS.md

Nix flake for my machines: NixOS, nix-darwin (macOS), and standalone Home
Manager. The README explains the design. This file covers what an agent needs
to work here safely.

## Layout

- `config/hosts.nix`, `config/users.nix`, `config/overlays.nix`: the data.
  Hosts, users, and the overlays every config shares.
- `lib/`: turns `config/` into the flake outputs. `flake.nix` only declares
  inputs, checks, and the dev shell.
- `home/programs/<name>/<name>.nix`: one Home Manager program per folder,
  wrapped by `home/lib/mkHomeModule.nix`. It adds the
  `dotfiles.programs.<name>.enable` option and the `mkSymlink` helper.
- `home/users/<username>.nix`: which programs a user gets, and where.
- `system/modules/{nixos,darwin}/<name>/<name>.nix`: system modules, with
  `dotfiles.modules.<name>.enable`.
- `system/hosts/<hostname>.nix`: which modules a host gets, plus settings only
  that host needs (boot loader, firewall, keyboard layout).
- `bin/`: helper scripts. Each one runs inside the flake's dev shell.

## Hosts

| Host                    | Build        | System           |
| ----------------------- | ------------ | ---------------- |
| `framework`             | NixOS        | `x86_64-linux`   |
| `temis`                 | NixOS        | `x86_64-linux`   |
| `thinkpad`              | Home Manager | `x86_64-linux`   |
| `Remote-Nelson-Estevao` | nix-darwin   | `aarch64-darwin` |

Agents run on the Linux machine. You can't run commands on the Mac. Ask me to
run Mac-only commands and paste the output back.

## Rules

- **Flakes only see tracked files.** `git add` a new file before you build or
  evaluate, or Nix acts as if it doesn't exist.
- **Host choices go in user and host files, not in modules.** Use
  `enableFor` / `disableFor` with roles (`desktop`, `server`, `linux`,
  `darwin`) or host names in `home/users/*.nix`. A module should not check the
  host name.
- **Prefer roles over host names.** A new desktop should need one line in
  `config/hosts.nix`, not edits to user files.
- **Mark one-OS modules** with `platforms = [ "linux" ]` or `[ "darwin" ]`
  next to the settings. Turning one on for the wrong OS then fails with a clear
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
- **Never change `stateVersion` or `darwinStateVersion`** on an existing host.
- **New program, module, user, or host:** use `bin/new` or `bin/setup`. Don't
  write the files by hand. `bin/new module <name> --darwin` makes a nix-darwin
  module.

## Check your work

Run these before you say a change works:

```shell
bin/lint          # deadnix, statix, nixfmt --check (CI runs it first)
bin/format        # fixes nixfmt errors
bin/check --eval  # evaluates every config, Mac ones too; builds nothing
```

`bin/check --eval` takes about a minute. It catches option and assertion
errors in all seven configs, NixOS, nix-darwin and Home Manager, without a
full build. The Mac configs evaluate fine from Linux.

To check one config while you work, evaluate just that one:

```shell
nix eval --raw '.#homeConfigurations."nelson@framework".activationPackage.drvPath'
```

`bin/check` with no flag builds what CI builds. It is slow. Use it for
changes to `lib/` or `flake.nix`.

## Ask first

- `bin/rebuild`: switches my live system or home and may need `sudo`.
- `bin/autoclean`: deletes old generations with `sudo`.
- `bin/update`: moves every flake input.
- Any `git push`, and any commit unless I asked for one.

## Code style

- Nix: `nixfmt`, two-space indent. `statix.toml` turns off `empty_pattern`
  and `repeated_keys` on purpose. Don't "fix" those.
- Comments say why, in plain words. Section breaks look like
  `# ── Name ─────`.
- Scripts in `bin/` are xonsh with docopt. Copy the shebang, the `Usage:`
  block, and the `# vim: ft=xonsh` modeline from an existing script. Full
  rules: `home/programs/claude/skills/scripting-conventions/SKILL.md`.
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
