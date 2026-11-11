[releases]: https://github.com/nelsonmestevao/dotfiles/releases/latest
[ci]: https://github.com/nelsonmestevao/dotfiles/actions/workflows/ci.yml
[license]: #-license
[spells]: https://github.com/nelsonmestevao/spells

<h1 align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/.github/header-LIGHT.png">
  <source media="(prefers-color-scheme: light)" srcset="/.github/header-DARK.png">
  <img alt="Dotfiles" src="/.github/header-DARK.png" width="750">
</picture>
</h1>

[![Latest Release](https://img.shields.io/github/release-pre/nelsonmestevao/dotfiles.svg?style=flat-square)][releases]
[![GitHub Actions CI](https://img.shields.io/github/actions/workflow/status/nelsonmestevao/dotfiles/ci.yml?style=flat-square)][ci]
[![License](https://img.shields.io/github/license/nelsonmestevao/dotfiles?logo=WTFNMFPL&style=flat-square)][license]
![Repo size](https://img.shields.io/github/repo-size/nelsonmestevao/dotfiles.svg?style=flat-square)

I enjoy customizing every aspect of my system. This repository contains my
complete setup — from configuration files for the tools I use (managed through
symlinks) to the declarative configuration of my entire system using the Nix
package manager, language, and operating system.

If you're just getting started, feel free to use my setup (_I don't mind_ — see
the [LICENSE][license]). But for your own good, **take the time to read through
it**. You won't get the most out of it otherwise.

<div align="center">
  <img alt="screenshot" src=".github/screenshot.png" width="85%"/>
</div>

<div align="center" class="flex">
  <sub>Light and Dark mode support.</sub><br/>
  <img alt="darkmode" src=".github/dark-mode.png" width="45%"/>
  <img alt="lightmode" src=".github/light-mode.png" width="45%"/>
</div>

<div align="center">
  <sub>Desktop apps like VS Code and Zen Browser.</sub><br/>
  <img alt="apps" src=".github/desktop-apps.png" width="85%"/>
</div>

## 🧩 Overview

This configuration is as modular as I can make it. It's split into two main
layers:

- **`home/`** — portable Home Manager configuration that works across any Linux
distribution **and macOS**. Most modules run everywhere; platform-specific ones
like GNOME, Hyprland, or Vicinae are simply left disabled where they don't
apply, and cross-platform modules (e.g. Ghostty, Docker) adapt their config per
OS via `pkgs.stdenv.isDarwin`.

- **`system/`** — OS-level configuration for both **NixOS** (Linux) and
**nix-darwin** (macOS). It holds only what's truly necessary for the system
layer (at least I try to), with modules split by platform under
`system/modules/nixos/` and `system/modules/darwin/`.

Together these produce three kinds of builds: NixOS hosts, nix-darwin (macOS)
hosts, and standalone Home Manager setups on any other machine. These are my
hosts today:

| Host                    | Build             | Roles     | System           | What runs there                           |
| ----------------------- | ----------------- | --------- | ---------------- | ----------------------------------------- |
| `framework`             | NixOS             | `desktop` | `x86_64-linux`   | GNOME desktop with my full set of apps    |
| `temis`                 | NixOS             | `server`  | `x86_64-linux`   | No desktop: SSH, Tailscale, and Docker    |
| `thinkpad`              | Home Manager only | —         | `x86_64-linux`   | Another Linux distro; only my home config |
| `Remote-Nelson-Estevao` | nix-darwin        | `desktop` | `aarch64-darwin` | A Mac managed by [Workbrew] (MDM)         |

### How modules work

Each program lives in its own folder under `home/programs/` as a self-contained
module. A helper called `mkHomeModule` wraps each one, providing a
`dotfiles.programs.<name>.enable` option and a `mkSymlink` function for
linking config files back to this repo.

> [!NOTE]
> `mkSymlink` creates **true symlinks** (on Linux and macOS alike) pointing
> directly from your home directory into this repo, so you can edit config files
> in place and see changes immediately — no rebuild needed. This is how I like
> it. A path that is not in the repo fails the build, so a link can't dangle.
>
> By default, Nix/Home Manager copies files into the read-only Nix store,
> requiring a rebuild for every change. This provides more guarantees like
> immutability. If you prefer that approach, replace `mkSymlink` calls with the
> standard `source` attribute:
> ```nix
> # Instead of:
> xdg.configFile."ghostty/config" = mkSymlink "config";
>
> # Use the standard Nix way:
> xdg.configFile."ghostty/config".source = ./config;
> ```

A module that only runs on one OS says so with `platforms = [ "linux" ]` or
`[ "darwin" ]`, next to its settings. Turning it on for a host on the other OS
stops the build with a message that names the host, instead of failing deep
inside a package build. Most modules run everywhere and leave it out.

Similarly, system-level concerns live under `system/modules/`, split by platform
into `nixos/` and `darwin/`. Each module provides a
`dotfiles.modules.<name>.enable` option — the NixOS side covers things like
audio, boot, networking, and Docker, while the macOS (nix-darwin) side currently
manages Homebrew (see [macOS notes](#-macos--nix-darwin)).

#### Where things are wired together

- **`config/hosts.nix`** — lists each host (see
  [What goes into a host entry](#what-goes-into-a-host-entry)).
- **`config/users.nix`** — defines each user (see
  [What goes into a user entry](#what-goes-into-a-user-entry)).
- **`config/overlays.nix`** — the nixpkgs overlays every host and user shares (see
  [Using another flake](#using-another-flake)).
- **`home/users/<username>.nix`** — toggles which programs a user gets.
- **`system/hosts/<hostname>.nix`** — toggles which system modules a host gets.
  It also holds settings that only that host needs, like its boot loader. The
  modules hold only what all hosts share.
- **`flake.nix`** — declares the flake inputs and passes them on. The code in
  `lib/` turns `config/` into the flake's outputs.

Two helpers control what runs where. Both take host names, roles, or a mix:

```nix
# home/users/nelson.nix
dotfiles.programs.nvim.enable = true;                                 # everywhere
dotfiles.programs.zed.enable = enableFor [ "desktop" ];               # hosts with the desktop role
dotfiles.programs.jetbrains.enable = enableFor [ "framework" ];       # only on framework
dotfiles.programs.herdr-core.enable = enableFor [ "desktop" "temis" ]; # desktops and temis
dotfiles.programs.vscode.enable = disableFor [ "server" ];            # everywhere except servers
```

Each host also gets a role for its OS, `"linux"` or `"darwin"`. It comes from
the host's `system`, so you never list it. Use `enableFor [ "linux" ]` for
programs that only run on Linux. Both names always work, even when no host
runs that OS.

Use roles where you can. A new desktop then needs one line in
`config/hosts.nix`, with no edits to the user files. Two rules keep this safe:

- A name that is neither a host nor a role stops the build, so a typo can't
  quietly turn a program off.
- A role can't have the same name as a host, so every name means one thing.

```nix
# system/hosts/framework.nix
dotfiles.modules.audio.enable = true;
dotfiles.modules.docker.enable = true;
dotfiles.modules.tailscale.enable = true;
```

## 🚀 Installing

> [!WARNING]
> Helper scripts are available in the `bin/` directory.
> **Read them before running anything** — as always, never execute code you don't
> understand or trust.

The only requirement is to have NixOS, nix-darwin, or the Nix package manager
installed.

### 1. Clone the repos

Start by cloning my `dotfiles` into `~/.dotfiles`:

```shell
git clone https://github.com/nelsonmestevao/dotfiles ~/.dotfiles
```

You can also clone my [`spells`][spells] into `~/.spells`. Spells are the small
shell scripts I use every day. They're optional: zsh only loads them when
`~/.spells/spells.init` exists. But there's a lot of goodies there.

```shell
git clone https://github.com/nelsonmestevao/spells ~/.spells
```

### 2. Add your user and host

`bin/rebuild` picks the config that matches the machine's hostname and your
username. On a new machine, add both first, or the build fails.

The fast way is `bin/setup`. It asks a few questions, writes the files, and adds
the entries to `config/`:

```shell
bin/setup user <username>  # home/users/<username>.nix + an entry in config/users.nix
bin/setup host <hostname>  # system/hosts/ files + an entry in config/hosts.nix
```

Add the user first, since `bin/setup host` asks which users go on the host. It
also asks for the host's roles.

You can pass the answers as flags instead. Anything you leave out is asked for,
or, with no terminal (a script or an agent), set to its default when it has
one:

```shell
bin/setup user alice --name "Alice Smith" --groups docker,wheel
bin/setup host box --platform nixos --system x86_64-linux --users alice --roles server
```

Without a terminal, `bin/setup host` writes a stub `hardware.nix` instead of
reading the hardware of the machine it runs on.

To do it by hand:

1. **Add your user** to `config/users.nix` and create
   `home/users/<username>.nix`. Use `nelson.nix` as a reference.
2. **Add your host** to `config/hosts.nix`. Set its `system`, its `users`, its
   `roles` (like `[ "desktop" ]`), its `stateVersion` (the release you are
   installing, like `"26.05"`), and `platform = "nixos"` or
   `platform = "darwin"`. Leave `platform` out for a standalone Home Manager
   host. A Mac also needs `darwinStateVersion`.
3. **Add the host's system files:**
   - **NixOS:** both `system/hosts/<hostname>.nix` and
     `system/hosts/<hostname>/hardware.nix`. Make the hardware file on the
     target machine with `nixos-generate-config --show-hardware-config`. Also
     set a boot loader (for example `boot.loader.systemd-boot.enable = true;`)
     in the host file. The `boot` module doesn't set one, so the build fails
     without it.
   - **nix-darwin:** `system/hosts/<hostname>.nix` (see
     `Remote-Nelson-Estevao.nix`).
   - **Home Manager only:** nothing.
4. **Pick your programs** by setting `dotfiles.programs.<name>.enable = true` in
   your user file.

> [!IMPORTANT]
> Flakes only see files that git tracks. Run `git add` on new files before you
> build. `bin/setup` does this for you.

### 3. Build it

`bin/rebuild` detects the platform and drives NixOS or nix-darwin accordingly.

```shell
bin/rebuild            # rebuild both OS and home config
bin/rebuild os         # rebuild only the system config (NixOS or nix-darwin)
bin/rebuild home       # rebuild only the home-manager configuration
bin/rebuild os --boot  # activate on next boot (handy for major release upgrades)
```

On a Home Manager–only host, run `bin/rebuild home`. Plain `bin/rebuild` also
tries to rebuild the OS, which fails there.

To see what would change first, run `bin/build`. It takes the same `os` and
`home` arguments, builds the configs, and prints the package diff. It doesn't
switch, so it needs no `sudo`.

### What goes into a host entry

Each host in `config/hosts.nix` has these fields:

- **`system`** — like `x86_64-linux` or `aarch64-darwin`.
- **`platform`** — `"nixos"` or `"darwin"`. Leave it out for a standalone
  Home Manager host.
- **`roles`** — what the host is for, like `[ "desktop" ]`. Optional.
- **`users`** — the users from `config/users.nix` that get a home config there.
- **`stateVersion`** — the release the host was first installed with, like
  `"26.05"`. Home Manager and NixOS keep that release's defaults for stateful
  things, so never bump it. A Mac also sets **`darwinStateVersion`**, the
  nix-darwin version it was first installed with. `bin/setup host` fills both
  in.
- **`git.signingKey`** — the SSH key that signs commits on this host, as the
  public key or the path of its file. **`git.signingProgram`** is the program
  that signs with it, like 1Password's. Leave both out and commits aren't
  signed there.

Modules get the whole entry as `host`, so a module can read a host fact
without knowing the host's name.

### What goes into a user entry

Each user in `config/users.nix` has these fields:

- **`name`** — your full name. On NixOS it becomes the account's description.
- **`extraGroups`** — groups for the account on NixOS, like `wheel` or
  `docker`.
- **`extraSpecialArgs`** — extra arguments for your Home Manager modules.
  Optional.

Modules get the whole entry as `user`. Your git identity is not in the entry:
it's the file `home/programs/git/profiles/<username>.ini`, included when it
exists. Without it, git refuses to commit until you set an email.

### Using another flake

Packages from other flakes (Zen Browser, Claude Code, …) and `pkgs.unstable`
come in through the overlays in `config/overlays.nix`. Every NixOS, nix-darwin
and Home Manager configuration gets them. Some are short-term GNOME patches. To
use a new flake:

1. Add it to `inputs` in `flake.nix`.
2. Add its overlay to `config/overlays.nix`. It's in scope as
   `inputs.<name>`. If the overlay reuses the name of a nixpkgs package, give
   it a new name instead, like `orca-app` there. Otherwise it replaces that
   package on the systems too.

## 🧰 Scripts

All scripts live in `bin/`. Run any of them with `--help` for details. Run
them from inside the repo: each one starts in the flake's dev shell, so the
tools it needs come from `flake.lock`. With direnv, `cd` into the repo loads
that shell for you (`direnv allow` once).

| Script                         | What it does                                                         |
| ------------------------------ | -------------------------------------------------------------------- |
| `bin/rebuild [os\|home]`       | Builds the config and switches to it.                                |
| `bin/build [os\|home]`         | Builds the config and shows what would change, without switching.   |
| `bin/update`                   | Updates the flake inputs and lists what changed.                     |
| `bin/update --save`            | Same, then commits `flake.lock` with a note for each input.          |
| `bin/check`                    | Runs `nix flake check` for every system.                             |
| `bin/check --eval`             | Evaluates every config without building anything (about a minute).  |
| `bin/lint`                     | Runs deadnix, statix and nixfmt, like CI does before it builds.      |
| `bin/format`                   | Formats every Nix file (`nix fmt`).                                  |
| `bin/autoclean`                | Deletes generations older than 7 days and frees space (uses `sudo`). |
| `bin/setup user\|host <name>`  | Adds a user or host (see [Installing](#-installing)).                |
| `bin/new program <name>`       | Creates a Home Manager program in `home/programs/<name>/`.           |
| `bin/new module <name>`        | Creates a NixOS module in `system/modules/nixos/<name>/`.            |
| `bin/new module <name> --darwin` | Creates a nix-darwin module in `system/modules/darwin/<name>/`.    |
| `bin/new extension <name>`     | Creates a GNOME extension in `home/programs/gnome/extensions/<name>/`. |

`bin/new` and `bin/setup` stage the files they create with `git add`, so the
flake sees them right away.

Coding agents get their rules from [`AGENTS.md`](AGENTS.md). For Claude Code,
[`.claude/settings.json`](.claude/settings.json) also makes it ask before it
runs `bin/rebuild`, `bin/autoclean`, `bin/update`, `sudo` or `git push`, and
lets it lint, check and build without asking.

To stay up to date:

```shell
bin/update --save  # update the flake inputs and commit flake.lock
bin/rebuild        # switch to the new versions
```

To move to a new NixOS release, bump `26.05` in `flake.nix`. Then run
`bin/rebuild os --boot` and reboot, so services don't hang while they restart.

## 🍎 macOS / nix-darwin

macOS hosts are built with [nix-darwin] and behave a little differently from
NixOS:

- **Nix is managed by [Determinate Nix]**, so nix-darwin's own Nix management is
  turned off (`nix.enable = false`) to avoid conflicts — Determinate owns
  flakes, `nix-command`, and garbage collection.
- **Homebrew is driven declaratively** through the
  `dotfiles.modules.homebrew.enable` module, which reconciles casks/formulae via
  `brew bundle` on activation. nix-darwin does **not** install Homebrew itself —
  install it once, manually, first.
- **Home Manager runs the same modules** as on Linux; Linux/Wayland-only ones
  (GNOME, Hyprland, Vicinae) stay disabled and evaluate cleanly.

### Using the Homebrew module on your own Mac

My Mac is managed by [Workbrew] (MDM), and the Homebrew module is set up for
that. On a normal Mac, change these in
`system/modules/darwin/homebrew/homebrew.nix`:

- **`prefix = "/opt/workbrew";`** — delete this line. nix-darwin then uses the
  normal Homebrew prefix (`/opt/homebrew` on Apple Silicon).
- **The `fpath` line at the bottom** — delete it too. It hides folders that
  Workbrew owns from zsh. Without Workbrew, it only hides Homebrew's own zsh
  completions.
- **`taps`, `brews`, and `casks`** — these are my apps. Swap in your own.

[nix-darwin]: https://github.com/nix-darwin/nix-darwin
[Determinate Nix]: https://docs.determinate.systems/
[Workbrew]: https://www.workbrew.com/

## 📄 License

This repository is licensed under the [WTFNMFPL](LICENSE.txt).

<div align="center">
  <sub>Use your tools well or use better tools.</sub>
</div>
