# Roadmap

What is worth doing next, most important first. Each item says why, what to
do, and how to know it is done. Every "why" was checked against the repo on
2026-11-20.

Many ideas come from ten well-known Nix configs, read on the same day:
[Misterio77], [ryan4yin], [Mic92], [mitchellh], [dustinlyons],
[EmergentMind], [wimpysworld], [fufexan], [srid] and [hlissner]. "Seen in"
names the ones that do it. Twenty ideas were weighed, each with two or three
ways to do it. The eight below were picked; the rest are at the end, so they
aren't weighed again without a new reason.

An older audit of about 40 items is in git history
(`git log -- ROADMAP.md`).

## 1. Make the backups trustworthy

**Why:** [the timers](system/timers/nelson.nix) back up to three Restic
repositories with no retention, so they grow forever. Nothing runs
`restic check`, nothing tells you when a backup fails, and all three start at
17:00 on weekdays over the same paths. A backup you have never restored is a
guess.

**Do:**

- Add `pruneOpts`, like `--keep-daily 7 --keep-weekly 5 --keep-monthly 12`.
- Add `checkOpts`, or a weekly `restic check --read-data-subset=5%`.
- Send a desktop notification when a backup unit fails (`OnFailure`).
- Start the three repositories at different times.
- Every few months, restore one folder to `/tmp` from each repository. Write
  the steps in the README.

**Done when:** the number of snapshots stays flat for weeks, a failed run
shows a notification, and a restore from each repository works.

## 2. A `bin/doctor` for what is made by hand

**Why:** the Restic password (`~/.config/restic/restic.pw`), the rclone
remotes and `~/.zshenv.local` are made by hand on each machine. A new machine
needs steps that no file lists, and the backup timers fail without the
password file.

**Seen in:** nine of the ten keep secrets in the repo, encrypted, with
sops-nix or agenix. That was weighed and left out for now: there are few
secrets here, and rclone rewrites its config when a login token refreshes, so
that file can't be a read-only secret.

**Do:** write `bin/doctor`. It checks each hand-made file on this machine
(the Restic password, the rclone remotes the timers use, `~/.zshenv.local`,
the SSH key that signs commits) and says what is missing and how to make it.
The secrets stay out of the repo.

**Done when:** on a fresh machine `bin/doctor` names every file it lacks, and
on a finished one it says nothing is missing.

## 3. Fix three nvim bugs

**Why:** found with nvim 0.12 on 2026-11-20:

- The typo maps in [keymaps.lua](home/programs/nvim/keymaps.lua) turn every
  `W` and `Q` you type on the command line into lowercase. `/Word` searches
  for `word`.
- `j` and `k` map to `gj` and `gk`, so `5j` moves five screen lines, not the
  five real lines the relative numbers show.
- `gd` and `K` are mapped everywhere, so they break in a file with no
  language server.

**Do:** user commands (`:W`, `:Q`, `:Wq`, `:Wa`, `:Qall`, each with `!`) in
place of the typo maps; `gj` and `gk` only without a count; `gd` set when a
language server attaches, and no map for `K`, which nvim sets itself there.

**Done when:** `/Word` finds `Word`, `5j` lands on the line numbered 5, and
`K` opens help in a help file.

## 4. Quiet the warning on every evaluation

**Why:** every `bin/check` prints "Using 'builtins.derivation' to create a
derivation named 'options.json'" four times, once for each home. It comes
from Home Manager's man page: with `manual.manpages.enable = false` the
warning is gone (tested).

**Do:** turn that man page off in [home/default.nix](home/default.nix).
`man home-configuration.nix` goes with it; the options are still on the web.

**Done when:** `bin/check --eval` prints no warning from the homes.

## 5. Check and format the other languages

**Why:** the lint check covers Nix, shell, xonsh, zsh, the workflow and the
docs' links. The 56 JavaScript files of the Herdr mods and the 6 Lua files of
nvim get no check at all, and
[remote.test.mjs](home/programs/herdr-app/mods/profile-pictures/remote.test.mjs)
is a test that nothing runs.

**Seen in:** Mic92 formats every language with one command.

**Do:**

- Run that test in `bin/test`.
- Parse every JavaScript and Lua file in the lint check, so a syntax error
  fails before a switch.
- Make `bin/format` format every language through treefmt (nixfmt, shfmt,
  stylua, prettier). The first run reformats many files: keep it a commit of
  its own.

**Done when:** a syntax error in a mod fails `bin/lint`, and `bin/format`
leaves a clean tree.

## 6. A "command not found" that knows Nix

**Why:** [the handler](home/programs/zsh/handlers.zsh) prints a drawing and
the command's name. It can't say which package has the command.

**Seen in:** nix-index-database in EmergentMind, wimpysworld and srid.

**Do:** add nix-index-database as an input, with comma. The handler keeps its
drawing and also names the package, and `, cowsay hi` runs a command once
without installing it.

**Done when:** a missing command names its package, and `, cowsay hi` runs.

## 7. Start the shell faster

**Why:** a new zsh takes 0.40 to 0.43 seconds on the Mac (three runs, after a
warm-up).

**Do:** measure one start with `zprof`, see where the time goes, and cut only
what is slow. oh-my-zsh stays.

**Done when:** a new shell starts in under 0.2 seconds.

## 8. Make a reinstall repeatable

**Why:** both hardware files name the disks by the UUIDs of the first
install. A new disk means partitioning by hand and writing the file again.

**Seen in:** disko in seven of the ten.

**Do:** write a disko layout for each NixOS host, framework first, to match
its disks today. It is only read at install time, so the running systems
don't change.

**Done when:** an empty disk becomes the host with one documented command.

## Waiting

- **vicinae:** it comes from its own flake, which is newer than
  nixpkgs-unstable's copy (0.30.1 against 0.29.2 on 2026-11-20), and downloads
  from `vicinae.cachix.org`. Once nixpkgs-unstable catches up, take it from
  there and drop the flake input, its modules and the cache.

## Weighed and left out

Left out on 2026-11-20. Each is still true; pick one up if it starts to hurt.

- **SSH on temis:** [temis.nix](system/hosts/temis.nix) turns on SSH with the
  firewall off, and the server takes passwords. The ways in: keys and a
  firewall, SSH only over Tailscale, or the `srvos` server profile.
- **A weekly update of the inputs:** inputs move only when
  [bin/update](bin/update) is run by hand.
- **Homebrew upgrades on a switch:** `autoUpdate` and `upgrade` are on in
  [the Homebrew module](system/modules/darwin/homebrew/homebrew.nix), so the
  same commit gives a different Mac on different days.
- **A binary cache filled by CI:** herdr-app is patched here and compiles for
  about 35 minutes, in CI and again on framework.
- **Switching temis from the laptop**, and a temis that upgrades itself.
- **Saying what temis runs:** Docker is on, and no file lists its containers.
- **Secure Boot and a TPM unlock on framework** (lanzaboote).
- **More of the Mac in the repo:** Touch ID for `sudo`, the keyboard.
- **Default apps on GNOME** (`xdg.mimeApps`).
- **Listing the Flatpak apps** (nix-flatpak).
- **A dev shell that starts with a mistake in the data:** since #93, a typo in
  `config/hosts.nix` stops every `bin/` script at the start.
- **The Framework profile from `nixos-hardware`:** firmware updates were the
  part that mattered.
- **nvim, the rest:** linking the whole folder as `~/.config/nvim`, tracking
  `lazy-lock.json` and updating plugins on a schedule.

Things the same ten configs do that don't fit here:

- **Impermanence:** a root that is wiped on every boot. A lot of care for a
  laptop that is already rebuilt from this repo.
- **A theming framework** (catppuccin/nix, stylix): the themes here are
  hand-made files, linked live.
- **flake-parts or blueprint:** `lib/` already does this job, in less.
- **Home Manager as a system module:** standalone keeps thinkpad and the Mac
  the same as the NixOS hosts.
- **A Justfile:** `bin/` covers it, with tests.
- **Pre-commit hooks** (git-hooks.nix): `bin/lint` and CI catch the same.
- **Project templates:** mise and direnv set up each project already.

[Misterio77]: https://github.com/Misterio77/nix-config
[ryan4yin]: https://github.com/ryan4yin/nix-config
[Mic92]: https://github.com/Mic92/dotfiles
[mitchellh]: https://github.com/mitchellh/nixos-config
[dustinlyons]: https://github.com/dustinlyons/nixos-config
[EmergentMind]: https://github.com/EmergentMind/nix-config
[wimpysworld]: https://github.com/wimpysworld/nix-config
[fufexan]: https://github.com/fufexan/dotfiles
[srid]: https://github.com/srid/nixos-config
[hlissner]: https://github.com/hlissner/dotfiles
