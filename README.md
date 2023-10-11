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
holds how I do it. If you are just starting out you could use mine (_I don't
care or mind_, see [LICENSE][license]) but for your own sake **read them**. You
will not get the most out of it without.

Start by reading my Neovim configuration. It follows a literate configuration
where it's documentation is the configuration files it selves. I write them
using markdown and Neovim will interpret only the code blocks.

<div align="center">
  <img alt="screenshot" src=".github/screenshot.png" width="85%"/>
</div>

## :rocket: Installing

I follow a very modular approach. If you don't want something you can just
remove it's folder. Imagine you don't want Neovim. You can just delete `nvim`
folder. It's that simple.

> **Warning**
> As you probably know, you shouldn't just run any script that you do not trust.
You shouldn't just trust my `install` script. You should read it and all the
helpers that it relies on.

Start by cloning my `dotfiles` into `~/.dotfiles`. You should do the same with
my `spells` repository. Some scripts needed are there.

```shell
git clone https://github.com/nelsonmestevao/dotfiles ~/.dotfiles
git clone https://github.com/nelsonmestevao/spells   ~/.spells
```

Depending on your Linux distribution you should change the `distro.sh`
accordingly.

```shell
cd ~/.dotfiles
./install
```

## :bomb: Uninstalling

```shell
cd ~/.dotfiles
./uninstall.sh
cd ~
rm -rf ~/.dotfiles
rm -rf ~/.spells
```

## :memo: License

This repository is licensed under the [WTFNMFPL](LICENSE.txt).

<div align="center">
  <sub>Use your tools well or use better tools.</sub>
</div>

