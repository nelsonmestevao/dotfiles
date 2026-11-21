# Roadmap

What is worth doing next, most important first. Each item says why, what to
do, and how to know it is done. Every "why" was checked against the repo on
2026-11-21.

Many ideas came from ten well-known Nix configs, read on 2026-11-20:
[Misterio77], [ryan4yin], [Mic92], [mitchellh], [dustinlyons],
[EmergentMind], [wimpysworld], [fufexan], [srid] and [hlissner]. Twenty ideas
were weighed, each with two or three ways to do it, and eight were picked.
Seven of those are done. What is left of the eighth is below, and the ideas
that were left out are at the end, so they aren't weighed again without a new
reason.

An older audit of about 40 items is in git history
(`git log -- ROADMAP.md`).

## Check on the machines

These changes were only evaluated from the Mac. Each needs one look on the
machine it is for:

- **framework, the backups:** the first backup after the switch deletes every
  snapshot the retention doesn't keep. Start one by hand with
  `sudo systemctl start restic-backups-mega` and read its log with
  `journalctl -eu restic-backups-mega`. To see the failure notice once, run
  `sudo systemctl start notify-failure@sync-books`.
- **framework, by hand:** `bin/doctor` should say nothing is missing, and
  `fwupdmgr update` should find the laptop's firmware.
- **framework, the disk layout:**
  [disks.nix](system/hosts/framework/disks.nix) guesses the drive's name
  (`/dev/nvme0n1`) and the size of the EFI partition (1 GiB). Check both
  against `lsblk`.
- **thinkpad:** the first switch prints one `sudo` command that sets up the
  graphics drivers for Nix programs. Run it.

## 1. A disk layout for temis

**Why:** framework's disk is written down for disko, so an empty disk becomes
the laptop with two commands. temis's
[hardware file](system/hosts/temis/hardware.nix) still names its disk by the
UUID of the first install, and nothing says how it was partitioned.

**Do:** write `system/hosts/temis/disks.nix` the way framework's is written:
the partitions temis has today, each made with the UUID its hardware file
already names. temis boots with GRUB from `/dev/sda`, not EFI.

**Done when:** the README's two commands work for temis too.

## Waiting

- **vicinae:** it comes from its own flake, which is newer than
  nixpkgs-unstable's copy (0.30.1 against 0.29.2 on 2026-11-20), and downloads
  from `vicinae.cachix.org`. Once nixpkgs-unstable catches up, take it from
  there and drop the flake input, its modules and the cache.

## Weighed and left out

Left out on 2026-11-20. Each is still true; pick one up if it starts to hurt.

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
