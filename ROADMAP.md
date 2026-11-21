# Roadmap

Nothing is queued. What is left: a look at each machine, one thing that waits
on nixpkgs, and the ideas that were weighed and left out, kept here so they
aren't weighed again without a new reason.

The ideas came in two rounds. Each was checked against the repo before it
was offered, with two or three ways to do it:

- **2026-11-20:** twenty ideas from ten well-known Nix configs:
  [Misterio77], [ryan4yin], [Mic92], [mitchellh], [dustinlyons],
  [EmergentMind], [wimpysworld], [fufexan], [srid] and [hlissner]. Eight were
  picked. All eight are done.
- **2026-11-21:** a second look at well-known configs, and at every tool
  installed here: is it still maintained, is there a better one. What was
  picked is merged (pull requests #120 to #143).

An older audit of about 40 items is in git history
(`git log -- ROADMAP.md`).

## Check on the machines

These changes were only evaluated from the Mac. Each needs one look on the
machine it is for, after a `git pull` and a `bin/rebuild` there.

On framework:

- **The backups:** the first backup after the switch deletes every snapshot
  the retention doesn't keep. Start one by hand with
  `sudo systemctl start restic-backups-mega` and read its log with
  `journalctl -eu restic-backups-mega`. To see the failure notice once, run
  `sudo systemctl start notify-failure@sync-books`.
- **By hand:** `bin/doctor` should say nothing is missing, and
  `fwupdmgr update` should find the laptop's firmware.
- **The disk layout:** [disks.nix](system/hosts/framework/disks.nix) guesses
  the drive's name (`/dev/nvme0n1`) and the size of the EFI partition
  (1 GiB). Check both against `lsblk`.
- **mise:** `mise settings get all_compile` should print `false`, and a new
  Node or Python should download, not compile. A runtime that won't start
  needs a library that nix-ld's list lacks: add it with
  `programs.nix-ld.libraries` in [nixos.nix](system/nixos.nix).
- **LaTeX:** `latexmk -pv` should open the PDF in zathura.
- **ansible:** `ap --version` should answer.

On temis:

- **The disk layout:** [disks.nix](system/hosts/temis/disks.nix) guesses the
  disk's name (`/dev/sda`, where GRUB goes today) and makes a GPT disk with
  a 1 MiB partition for GRUB. temis may have an older MBR disk today; a new
  install doesn't need to match it. Check the name against `lsblk`.
- **mise:** as on framework.

On thinkpad:

- **The graphics drivers:** the first switch prints one `sudo` command that
  sets them up for Nix programs. Run it.
- **The monthly cleanup:** `systemctl --user list-timers nh-clean` should
  list it. Its service needs `nix` on the PATH of the systemd session; if the
  first run fails, look there.
- **The prompt's icons:** the prompt expects a Nerd Font of version 3, which
  Nix installs only on desktops. If icons show as boxes here, the terminal's
  font is older.

On the Mac:

- **The monthly cleanup:** this should show the job, which runs on the first
  of the month. The system's generations still need `bin/autoclean`.

  ```shell
  launchctl print gui/$(id -u)/org.nix-community.home.nh-clean
  ```

On every machine:

- **The prompt:** in a folder with a `.tool-versions` or a `mise.toml`, the
  prompt shows each tool's version with its icon
  ([prompt-mise.zsh](home/programs/zsh/prompt-mise.zsh)).
- **tldr:** the first `tldr tar` fetches its pages by itself.

## Waiting

- **vicinae:** it comes from its own flake, which is newer than
  nixpkgs-unstable's copy (0.30.1 against 0.30.0 on 2026-11-21), and downloads
  from `vicinae.cachix.org`. Once nixpkgs-unstable catches up, take it from
  there and drop the flake input, its modules and the cache.

## Weighed and left out

Each is still true. Pick one up if it starts to hurt.

Left out on 2026-11-20:

- **A faster shell start:** measured on the Mac on 2026-11-21. A new zsh
  takes about 0.39 seconds, but powerlevel10k's instant prompt shows the
  prompt at once. No part is slow on its own: mise 43 ms, zsh-autopair 28,
  oh-my-zsh's completion audit about 30, zoxide 17. Skipping the audit only
  brought 0.35 seconds down to 0.32.
- **Formatting the JavaScript:** the Herdr mods are written densely, and
  prettier would grow them from about 9,400 lines to about 30,700. The lint
  check parses them instead.
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

Left out on 2026-11-21:

- **Deleting comments:** the ones that came with an app's example config, the
  wizard's in `p10k.zsh`, and settings turned off by a `#`. They stay.
- **The medium TeX Live:** 2.6 GB where the full one is 5.9 GB on framework.
  The full one always builds a document.
- **Building the NixOS systems in CI:** temis would take 131 small
  derivations and 712 MiB, framework 5.1 GiB. `bin/build` on the machine
  stays the first real build.
- **A notice on the phone when a backup fails**, and one for a backup that
  never ran (ntfy, Healthchecks).
- **A commit that goes through when the secret scanner is missing:** between
  a `git pull` and a `bin/rebuild`, the hook is there and betterleaks is not.
  A rebuild right after the pull avoids it.
- **A terminal spreadsheet or CSV viewer** (sc-im, csvview.nvim, csvlens).
- **Smaller ones:** an `unstable` name in the flake registry, a package for
  git-fuzzy, a newer mise so Erlang is downloaded too, and the repo's options
  in Zed as nvim has them.

Things well-known configs do that don't fit here:

- **Impermanence:** a root that is wiped on every boot. A lot of care for a
  laptop that is already rebuilt from this repo.
- **A theming framework** (catppuccin/nix, stylix): the themes here are
  hand-made files, linked live.
- **flake-parts, blueprint, import-tree:** `lib/` already does this job, in
  less.
- **Home Manager as a system module:** standalone keeps thinkpad and the Mac
  the same as the NixOS hosts.
- **A Justfile:** `bin/` covers it, with tests.
- **Pre-commit hooks for lint** (git-hooks.nix): `bin/lint` and CI catch the
  same. The one hook here scans for secrets.
- **Project templates:** mise and direnv set up each project already.
- **A secrets manager** (sops-nix, agenix): the only fixed secret is one
  restic password, and rclone rewrites its own tokens. `bin/doctor` lists
  what must be made by hand.
- **Starship:** Powerlevel10k is still maintained, and the prompt has its own
  mise segment now.
- **Another Nix** (Lix, Determinate Nix on the NixOS hosts) or faster
  evaluation (nix-eval-jobs): evaluating every config takes under a minute.
- **Installing from afar** (nixos-anywhere, nixos-facter): the disk layouts
  are kept apart from the configs on purpose.
- **system-manager, Home Manager's restic, atuin, carapace, television,
  darkman, rustic, `vim.pack`:** each was looked at, and none had a gain
  here.

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
