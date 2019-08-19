[semaphoreci]: https://semaphoreci.com/nelsonmestevao/dotfiles
[releases]: https://github.com/nelsonmestevao/dotfiles/releases/latest
[license]: #memo-license

<h1 align="center">
  <img src="https://user-images.githubusercontent.com/19409687/54166758-980b4200-445e-11e9-8e81-f0cd7ba70fb5.png" alt="dotfiles" width="750px">
</h1>

[![Build Status](https://semaphoreci.com/api/v1/nelsonmestevao/dotfiles/branches/master/badge.svg)][semaphoreci]
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
  <img alt="screenshot" src="screenshot.png" width="85%"/>
</div>

## :rocket: Installing

I follow a very modular approach. If you don't want something you can just
remove it's folder. Imagine you don't want Neovim. You can just delete `nvim`
folder. It's that simple.


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
make install
```

## :bomb: Uninstalling

```shell
cd ~/.dotfiles
make uninstall
cd ~
rm -rf ~/.dotfiles
rm -rf ~/.spells
```

## :warning: Disclaimer

As you probably know, you shouldn't just run my Makefile without reading it
first. And if you read it, you will understand that it calls other scripts like
`install.sh` which depend on `helpers.sh`. Read those, it's the only way that
you can trust what it is doing.

## :memo: License

This repository is licensed under the [WTFNMFPL](LICENSE.txt).

<div align="center">
  <sub>Use your tools well or use better tools.</sub>
</div>

