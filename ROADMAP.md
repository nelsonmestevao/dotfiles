# Roadmap

What is worth doing next, most important first. Each item says why, what to
do, and how to know it is done. Every "why" was checked against the repo on
2026-11-17.

This replaces a long audit of about 40 items. Most of those are done, or cost
more than they give in a one-person repo. The old file is in git history
(`git log -- ROADMAP.md`) if one of them starts to hurt.

## 1. Lock down SSH on temis

**Why:** [temis.nix](system/hosts/temis.nix) turns on SSH and Docker and turns
the firewall off. Nothing sets sshd options or authorized keys, so NixOS lets
you log in with a password. A server that takes passwords is the biggest risk
in this repo.

**Do:**

- Keep your public keys in the repo and give them to the user's
  `openssh.authorizedKeys.keys`.
- Turn off `PasswordAuthentication` and `KbdInteractiveAuthentication`, and set
  `PermitRootLogin = "no"`.
- Turn the firewall back on and open port 22 and only what you mean to share.
  Docker opens published ports past the NixOS firewall, so bind containers to
  `127.0.0.1` unless they are meant to be public.
- temis is remote: keep a session open while you switch, and test a new login
  before you close it.

**Done when:** `ssh -o PubkeyAuthentication=no temis` is refused, and a port
scan from another machine shows only the ports you chose.

## 2. Make the backups trustworthy

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

## 3. Run `bin/update` every week

**Why:** inputs move only when you remember to update, and an upstream break
then shows up in the middle of other work, with an hour of compiling.
[bin/update](bin/update) is ready for it: it commits only the lockfile and
runs without a terminal.

**Do:** add a weekly workflow that runs `bin/update --save` on a branch and
opens a pull request, so CI builds the new inputs before you switch to them.

**Done when:** the weekly pull request shows up with CI's result on it.

## 4. Stop surprise Homebrew upgrades on the Mac

**Why:** [the Homebrew module](system/modules/darwin/homebrew/homebrew.nix)
sets `autoUpdate`, `upgrade` and `cleanup = "uninstall"`. The same commit then
gives a different Mac on different days. The old roadmap notes that `cleanup`
already broke one `bin/rebuild os`.

**Do:** turn off `autoUpdate` and `upgrade`, so a switch installs only what the
module lists. Upgrade on purpose, with `brew upgrade` or a `bin/` command.

**Done when:** two switches a week apart, from the same commit, change nothing
in Homebrew.

## 5. Finish the nvim cleanup

**Why:** checked by hand on 2026-11-17:

- The typo maps in [keymaps.lua](home/programs/nvim/keymaps.lua) turn every `W`
  and `Q` you type on the command line into lowercase. `/Word` searches for
  `word`.
- `j` and `k` map to `gj` and `gk`, which breaks counts like `5j` on wrapped
  lines.
- The LSP keymaps apply everywhere, so `gd` fails in a file with no language
  server instead of doing vim's own jump.
- [init.lua](home/programs/nvim/init.lua) finds the other files through
  `$DOTFILES`. [plugins.lua](home/programs/nvim/plugins.lua) is 895 lines, and
  no `lazy-lock.json` is tracked, so plugin versions move on their own.
- 37 of 42 plugins load at startup (about 165 ms). `tokyonight`,
  `editorconfig-vim` and `FixCursorHold.nvim` do nothing on nvim 0.12.

**Do:**

- Fix the three bugs: user commands for the typos, `gj` only without a count,
  LSP keymaps in an `LspAttach` autocmd.
- Link the whole folder as `~/.config/nvim`, with `lua/config/` for options,
  keymaps and commands, and one file per area in `lua/plugins/`, loaded with
  lazy's `import = "plugins"`.
- Track `lazy-lock.json`.
- Drop the dead plugins. Use `opts` instead of `config` functions that only
  call `setup()`, and `keys` or `cmd` so plugins load on first use.

**Done when:** `/Word` finds `Word`, `env -u DOTFILES nvim` starts with no
errors, and `:Lazy restore` gives the same plugins on every host.

## 6. Small wins

- **Framework:** [hardware.nix](system/hosts/framework/hardware.nix) is the
  generated file and nothing more. Import the Framework profile from
  `nixos-hardware` (power and suspend fixes) and turn on `services.fwupd` for
  firmware updates.
- **thinkpad:** it runs Home Manager on another distro, and nothing sets
  `targets.genericLinux.enable`. Turn it on for every home-only host, so Nix
  programs find fonts, icons, desktop entries and the graphics drivers.
- **vicinae:** finish pull request #30. The old roadmap measured about an hour
  of compiling for every vicinae bump.
