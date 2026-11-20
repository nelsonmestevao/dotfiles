# Roadmap

What is worth doing next, in five groups, the most important first in each.
Each item says why and gives the ways it could be done. Every "why" was
checked against the repo on 2026-11-20.

Many ideas come from ten well-known Nix configs, read on the same day:
[Misterio77], [ryan4yin], [Mic92], [mitchellh], [dustinlyons],
[EmergentMind], [wimpysworld], [fufexan], [srid] and [hlissner]. "Seen in"
names the ones that do it.

An older audit of about 40 items is in git history
(`git log -- ROADMAP.md`).

## Safety

### 1. Lock down SSH on temis

**Why:** [temis.nix](system/hosts/temis.nix) turns on SSH and Docker and turns
the firewall off. Evaluated, the server takes passwords and
keyboard-interactive logins, and the repo gives the user no authorized keys.
A server that takes passwords is the biggest risk in this repo.

**Options:**

- **A.** Public keys in the repo, passwords and root login off, the firewall
  on with port 22 open.
- **B.** The same, but SSH answers only over Tailscale: port 22 is open on
  `tailscale0` and nowhere else.
- **C.** A, plus the server profile from `nix-community/srvos`, which sets
  these and other server defaults.

**Done when:** `ssh -o PubkeyAuthentication=no temis` is refused, and a port
scan from another machine shows only the ports you chose. temis is remote:
keep a session open while you switch, and test a new login before you close
it.

### 2. Make the backups trustworthy

**Why:** [the timers](system/timers/nelson.nix) back up to three Restic
repositories with no retention, so they grow forever. Nothing runs
`restic check`, nothing tells you when a backup fails, and all three start at
17:00 on weekdays over the same paths. A backup you have never restored is a
guess.

**Options:**

- **A.** All of it: `pruneOpts`, a weekly `restic check`, a desktop notice
  when a backup fails, three start times, and a restore drill in the README.
- **B.** Only retention and the failure notice.
- **C.** A, plus a ping to a dead-man's-switch service after each run. It
  also tells you when a backup did not run at all.

**Done when:** the number of snapshots stays flat for weeks, a failed run
shows a notice, and a restore from each repository works.

### 3. Keep secrets in the repo, encrypted

**Why:** the Restic password (`~/.config/restic/restic.pw`), the rclone
remotes and `~/.zshenv.local` are made by hand on each machine. A new machine
needs steps that no file lists, and the backup timers fail without the
password file.

**Seen in:** nine of the ten. sops-nix in Misterio77, Mic92, EmergentMind and
wimpysworld; agenix in dustinlyons, srid and hlissner; a `secrets/` folder in
ryan4yin and fufexan.

**Options:**

- **A.** sops-nix: each secret is encrypted to the hosts' SSH keys and
  decrypted at switch.
- **B.** agenix: the same idea with less to learn, one file per secret.
- **C.** No tool: a `bin/doctor` that checks each hand-made file and says
  what is missing.

**Done when:** a fresh machine gets working backups from one switch, or
`bin/doctor` names every file it lacks.

## Keeping current

### 4. Update the inputs every week

**Why:** inputs move only when you remember to update, and an upstream break
then shows up in the middle of other work. [bin/update](bin/update) is ready:
it commits only the lockfile and runs without a terminal.
[ci.yml](.github/workflows/ci.yml) is the only workflow.

**Seen in:** dustinlyons (a weekly `update-flake-lock` workflow), wimpysworld
(a twice-weekly one), Mic92 (Renovate, merged on its own when CI passes).

**Options:**

- **A.** A weekly workflow that runs `bin/update --save` on a branch and opens
  a pull request, in this repo's commit format.
- **B.** The `DeterminateSystems/update-flake-lock` action, which does the
  same with its own commit text.
- **C.** Renovate, which also moves the pinned GitHub Actions.

**Done when:** the weekly pull request shows up with CI's result on it.

### 5. Stop surprise Homebrew upgrades on the Mac

**Why:** [the Homebrew module](system/modules/darwin/homebrew/homebrew.nix)
sets `autoUpdate`, `upgrade` and `cleanup = "uninstall"`. The same commit then
gives a different Mac on different days.

**Options:**

- **A.** Turn off `autoUpdate` and `upgrade`. A switch installs only what the
  module lists; upgrade on purpose with `brew upgrade`.
- **B.** Turn off only `upgrade`. Homebrew still refreshes its list of
  formulae on a switch, but installed ones stay as they are.

**Done when:** two switches a week apart, from the same commit, change nothing
in Homebrew.

### 6. Let CI fill a binary cache

**Why:** herdr-app is patched here, so no public cache has it. CI compiles it
for about 35 minutes, and framework compiles it again on every bump.

**Seen in:** Misterio77 and Mic92 run their own cache; wimpysworld uses
FlakeHub Cache.

**Options:**

- **A.** Cachix: CI pushes what it builds, and the hosts download it.
- **B.** A cache on temis (attic or harmonia). Nothing leaves your machines,
  but temis has to be up and reachable.

**Done when:** a switch on framework after a herdr-app bump downloads it.

## Servers and installs

### 7. Switch temis from the laptop

**Why:** `bin/rebuild` only switches the machine it runs on. temis needs a
login, a pull and a rebuild there.

**Seen in:** Misterio77 (a `deploy.sh` around `nixos-rebuild --target-host`),
ryan4yin (colmena, and `system.autoUpgrade`), Mic92 (clan).

**Options:**

- **A.** `bin/rebuild --host temis`: build on framework, copy the result and
  switch over SSH.
- **B.** temis upgrades itself each night from GitHub with
  `system.autoUpgrade`.
- **C.** Both: A for a change you want now, B so it never falls behind.

**Done when:** temis runs a new commit without a login there.

### 8. Say what temis runs

**Why:** Docker is on, but no file says which containers run. A reinstalled
temis would come up empty.

**Options:**

- **A.** Declare each container with `virtualisation.oci-containers`.
- **B.** Keep the compose files in the repo and start them from a systemd
  unit.

**Done when:** a fresh temis runs the same services after one switch.

### 9. Make a reinstall repeatable

**Why:** both hardware files name the disks by the UUIDs of the first
install. A new disk means partitioning by hand and writing the file again.

**Seen in:** disko in seven of the ten.

**Options:**

- **A.** A disko layout for temis first, installed with nixos-anywhere the
  next time.
- **B.** disko for both hosts, written to match today's disks. It is only
  read at install time.
- **C.** No tool: the manual steps, written in the README.

**Done when:** an empty disk becomes the host with one documented command.

### 10. Secure Boot and disk unlock on framework

**Why:** framework's disk is encrypted, and it boots with systemd-boot and no
Secure Boot. The passphrase is typed on every boot.

**Seen in:** lanzaboote in Misterio77 and ryan4yin.

**Options:**

- **A.** lanzaboote for Secure Boot, and the TPM unlocks the disk.
- **B.** Only the TPM unlock (`systemd-cryptenroll`), with the passphrase as
  the fallback.

Either one needs you at the keyboard, and a mistake can keep the laptop from
booting.

## Daily use

### 11. Finish the nvim cleanup

**Why:** measured on 2026-11-20, with nvim 0.12:

- The typo maps in [keymaps.lua](home/programs/nvim/keymaps.lua) turn every
  `W` and `Q` you type on the command line into lowercase. `/Word` searches
  for `word`.
- `j` and `k` map to `gj` and `gk`, so `5j` moves five screen lines, not the
  five real lines the relative numbers show.
- `gd` and `K` are mapped everywhere, so they break in a file with no
  language server.
- [init.lua](home/programs/nvim/init.lua) finds the other files through
  `$DOTFILES`, and `lazy-lock.json` is not tracked. The Mac's is from July and
  lists 44 plugins, some long removed, so each machine runs its own versions.

Startup is no longer a problem: 29 plugins, 17 at start, 100 to 160 ms.

**Seen in:** Mic92 updates the nvim plugins in the same pull request that
updates the inputs.

**Options:**

- **A.** Fix the three bugs.
- **B.** A, then link the whole folder as `~/.config/nvim` and track
  `lazy-lock.json`.
- **C.** B, and the weekly update also moves the plugins.

**Done when:** `/Word` finds `Word`, `env -u DOTFILES nvim` starts with no
errors, and `:Lazy restore` gives the same plugins on every host.

### 12. A "command not found" that knows Nix

**Why:** [the handler](home/programs/zsh/handlers.zsh) prints a drawing and
the command's name. It can't say which package has the command.

**Seen in:** nix-index-database in EmergentMind, wimpysworld and srid.

**Options:**

- **A.** nix-index-database with comma: the handler names the package, and
  `, cowsay` runs a command once without installing it.
- **B.** Only comma.

### 13. Start the shell faster

**Why:** a new zsh takes 0.40 to 0.43 seconds on the Mac (three runs, after a
warm-up).

**Options:**

- **A.** Measure with `zprof`, trim what is slow, keep oh-my-zsh.
- **B.** Drop oh-my-zsh and load the ten plugins it is used for directly.

**Done when:** a new shell starts in under 0.2 seconds.

### 14. More of the Mac in the repo

**Why:** [darwin.nix](system/darwin.nix) sets the Dock and three Finder
options. Everything else on the Mac is set by clicking.

**Seen in:** Touch ID for `sudo` in ryan4yin, Mic92 and wimpysworld.

**Options:**

- **A.** Touch ID for `sudo`, one line.
- **B.** A, plus the keyboard (Caps Lock as Control, key repeat) and the
  trackpad.

The Mac is managed by Workbrew, which may overrule some settings.

### 15. Default apps on the GNOME desktop

**Why:** nothing sets which app opens a link, a PDF or an image
(`xdg.mimeApps`). A fresh framework asks, or picks its own.

**Seen in:** ryan4yin, wimpysworld and fufexan.

**Options:**

- **A.** Declare them for links, PDFs, images, video and text.
- **B.** Only the browser.

### 16. List the Flatpak apps

**Why:** framework turns Flatpak on, but no file lists the apps installed
with it.

**Seen in:** nix-flatpak in wimpysworld and srid.

**Options:**

- **A.** List the apps with nix-flatpak, so a switch installs them.
- **B.** Turn Flatpak off, if nothing needs it.

## The repo itself

### 17. Check the other languages

**Why:** the lint check covers Nix, shell, xonsh, zsh, the workflow and the
docs' links. The 56 JavaScript files of the Herdr mods and the 6 Lua files of
nvim get no check at all, and
[remote.test.mjs](home/programs/herdr-app/mods/profile-pictures/remote.test.mjs)
is a test that nothing runs.

**Seen in:** Mic92 formats every language with one command; ryan4yin and Mic92
run `typos`.

**Options:**

- **A.** Run that test in `bin/test`, and parse the JavaScript and Lua files
  in the lint check.
- **B.** A, plus one `bin/format` for every language, with treefmt.
- **C.** A, plus a spell check with `typos`.

### 18. Quiet the warning on every evaluation

**Why:** every `bin/check` prints "Using 'builtins.derivation' to create a
derivation named 'options.json'" four times, once for each home. It comes
from Home Manager's man page. With `manual.manpages.enable = false` the
warning is gone (tested).

**Options:**

- **A.** Turn the man page off. `man home-configuration.nix` goes with it.
- **B.** Leave it, and wait for Home Manager to fix the warning.

### 19. Let the dev shell start with a mistake in the data

**Why:** since #93, a typo in `config/hosts.nix` stops `nix develop`, so every
`bin/` script stops at the start: the dev shell is found by way of the
flake's packages, which are listed per host system.

**Options:**

- **A.** List the packages for the three tool systems instead. `nix develop`
  then never reads the data. The flake also offers packages for
  `aarch64-linux`, which no host runs.

### 20. The Framework hardware profile

**Why:** [hardware.nix](system/hosts/framework/hardware.nix) is the generated
file and nothing more. `nixos-hardware` has a profile for each Framework
model, with the light sensor, the AMD graphics setup and laptop defaults.

**Seen in:** nixos-hardware in six of the ten.

**Options:**

- **A.** Add the input and import the profile for the laptop's model.

## Waiting

- **vicinae:** it comes from its own flake, which is newer than
  nixpkgs-unstable's copy (0.30.1 against 0.29.2 on 2026-11-20), and downloads
  from `vicinae.cachix.org`. Once nixpkgs-unstable catches up, take it from
  there and drop the flake input, its modules and the cache.

## Looked at and left out

Things the same ten configs do that don't fit here:

- **Impermanence** (three of them): a root that is wiped on every boot. A lot
  of care for a laptop that is already rebuilt from this repo.
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
