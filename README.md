[releases]: https://github.com/nelsonmestevao/dotfiles/releases/latest
[ci]: https://github.com/nelsonmestevao/dotfiles/actions/workflows/ci.yml
[license]: #-license

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
hosts, and standalone Home Manager setups on any other machine.

### How modules work

Each program lives in its own folder under `home/programs/` as a self-contained
module. A helper called `mkHomeModule` wraps each one, providing a
`dotfiles.programs.<name>.enable` option and a `mkSymlink` function for
linking config files back to this repo.

> [!NOTE]
> `mkSymlink` creates **true symlinks** (on Linux and macOS alike) pointing
> directly from your home directory into this repo, so you can edit config files
> in place and see changes immediately — no rebuild needed. This is how I like
> it.
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

Similarly, system-level concerns live under `system/modules/`, split by platform
into `nixos/` and `darwin/`. Each module provides a
`dotfiles.modules.<name>.enable` option — the NixOS side covers things like
audio, boot, networking, and Docker, while the macOS (nix-darwin) side currently
manages Homebrew (see [macOS notes](#-macos--nix-darwin)).

#### Where things are wired together

- **`flake.nix`** — declares each host with its `system` and a `nixos = true` or
  `darwin = true` flag (omit both for a standalone Home Manager host).
- **`home/users/<username>.nix`** — toggles which programs a user gets.
- **`system/hosts/<hostname>.nix`** — toggles which system modules a host gets.

Two helpers make it easy to control what runs where per host:

```nix
# home/users/nelson.nix
dotfiles.programs.nvim.enable = true;                            # everywhere
dotfiles.programs.jetbrains.enable = enableFor [ "framework" ];  # only on framework
dotfiles.programs.vscode.enable = disableFor [ "thinkpad" ];     # everywhere except thinkpad
```

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
understand or trust.

Start by cloning my `dotfiles` into `~/.dotfiles`. You should do the same with
my `spells` repository. The spells are not a requirement but there's a lot of
goodies there.

```shell
git clone https://github.com/nelsonmestevao/dotfiles ~/.dotfiles
git clone https://github.com/nelsonmestevao/spells   ~/.spells
```

The only requirement is to have NixOS, nix-darwin, or the Nix package manager
installed. Then you are ready to build this configuration for your system —
`bin/rebuild` detects the platform and drives NixOS or nix-darwin accordingly.

```shell
bin/rebuild            # rebuild both OS and home config
bin/rebuild os         # rebuild only the system config (NixOS or nix-darwin)
bin/rebuild home       # rebuild only the home-manager configuration
bin/rebuild os --boot  # activate on next boot (handy for major release upgrades)
```

### Adapting for your own system

1. **Add your host** in `flake.nix` under the `hosts` attribute set, setting its
   `system` and the platform flag — `nixos = true`, `darwin = true`, or neither
   for a standalone Home Manager host.
2. **Add your user** in `flake.nix` under `users` and create a file at
   `home/users/<username>.nix` — use `nelson.nix` as a reference.
3. **If using NixOS**, add your hardware config under
   `system/hosts/<hostname>/hardware.nix`. **If using nix-darwin**, add a host
   file at `system/hosts/<hostname>.nix` (see `Remote-Nelson-Estevao.nix`).
4. **Pick your programs** by setting `dotfiles.programs.<name>.enable = true` in
   your user file.

## 🍎 macOS / nix-darwin

macOS hosts are built with [nix-darwin] and behave a little differently from
NixOS:

- **Nix is managed by [Determinate Nix]**, so nix-darwin's own Nix management is
  turned off (`nix.enable = false`) to avoid conflicts — Determinate owns
  flakes, `nix-command`, and garbage collection.
- **Homebrew is driven declaratively** through the
  `dotfiles.modules.homebrew.enable` module, which reconciles casks/formulae via
  `brew bundle` on activation. nix-darwin does **not** install Homebrew itself —
  install it once, manually, first. On this Mac, Homebrew is managed by
  [Workbrew] (MDM), so the module points at the `/opt/workbrew` prefix.
- **Home Manager runs the same modules** as on Linux; Linux/Wayland-only ones
  (GNOME, Hyprland, Vicinae) stay disabled and evaluate cleanly.

[Determinate Nix]: https://docs.determinate.systems/
[Workbrew]: https://www.workbrew.com/

## 📄 License

This repository is licensed under the [WTFNMFPL](LICENSE.txt).

<div align="center">
  <sub>Use your tools well or use better tools.</sub>
</div>
