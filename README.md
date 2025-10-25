[releases]: https://github.com/nelsonmestevao/dotfiles/releases/latest
[license]: #memo-license

<h1 align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="/.github/header-LIGHT.png">
  <source media="(prefers-color-scheme: light)" srcset="/.github/header-DARK.png">
  <img alt="Dotfiles" src="/.github/header-DARK.png" width="750">
</picture>
</h1>

[![Latest Release](https://img.shields.io/github/release-pre/nelsonmestevao/dotfiles.svg?style=flat-square)][releases]
[![License](https://img.shields.io/github/license/nelsonmestevao/dotfiles?logo=WTFNMFPL&style=flat-square)][license]
![Repo size](https://img.shields.io/github/repo-size/nelsonmestevao/dotfiles.svg?style=flat-square)

I really like to configure my system in every possible way. This repository
holds how I do it, by storing and symlinking the configuration files of my tools
as well the declarative configuration of my system by taking advantage of the
Nix package manager, programming language and even OS.

If you are just starting out you could use mine (_I don't care or mind_, see
[LICENSE][license]) but for your own sake **read them**. You will not get the
most out of it without.

<div align="center">
  <img alt="screenshot" src=".github/screenshot.png" width="85%"/>
</div>

## 🧩 Overview

This configuration is as modular as I can make it. It’s split into two main
directories:

- `home/`: portable configuration that works across any Linux distribution. Many
modules even work on macOS, except for platform-specific ones like GNOME or
Hyprland.

- `system/`: NixOS-specific configuration, containing only what’s truly
necessary for the system layer (at least I try to).

## 🚀 Installing

Every folder in `home/programs/*` is a module that brings the option
`dotfiles.programs.<name>.enable` and can be activated or deactivated but commenting
or setting it to false. Complex setups can easily be built by composing and
reusing these modular pieces.

> **Warning**
> Helper scripts are available in the bin/ directory.
> Read them before running anything — as always, never execute code you don’t
understand or trust.

Start by cloning my `dotfiles` into `~/.dotfiles`. You should do the same with
my `spells` repository. The spells are not a requirement but there's a lot of
goodies there.

```shell
git clone https://github.com/nelsonmestevao/dotfiles ~/.dotfiles
git clone https://github.com/nelsonmestevao/spells   ~/.spells
```

Then you are ready to build this configuration for your system. More
documentation will be provided on exactly how to customize things.

## 📄 License

This repository is licensed under the [WTFNMFPL](LICENSE.txt).

<div align="center">
  <sub>Use your tools well or use better tools.</sub>
</div>

