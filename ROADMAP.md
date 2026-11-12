# Dotfiles roadmap

This roadmap covers developer experience, simplification, reliability, CI, and
the operational pieces that are missing. It comes from three steps on
2026-11-12:

1. A source review. It read the code and ran nothing.
2. A hands-on review. It ran the helpers on the Mac, read 30 CI runs from
   GitHub's API, tried ideas in a scratch clone, and compared the repo with
   about 15 well-kept flake configs. It changed no file but this one and
   switched nothing.
3. A round of 24 questions to the owner. The answers are under
   [Decisions](#decisions) and are worked into the tasks.

Evidence marked **Verified** was run. Evidence marked **Measured** was timed.
**Decided** marks an answer from the owner. Anything else comes from reading
the source. The Linux hosts were not reached, so backups, timers, temis's
network, and NixOS activation are still untested.

Unchecked items describe proposed work. Checked items record what was done and
how it was checked.

## What to keep

The design is good. Every item below must leave these rules standing:

1. **A program is an option.** Each one is a folder,
   `home/programs/<name>/<name>.nix`, with `dotfiles.programs.<name>.enable`.
   System modules work the same way with `dotfiles.modules.<name>.enable`.
2. **Users and hosts choose.** User files and host files turn things on. A
   module never checks a host name or a user name.
3. **Roles first, host names for exceptions.** `enableFor` and `disableFor`
   take roles or host names. An unknown name stops the build.
4. **Data apart from machinery.** `config/` holds data, `lib/` builds the
   outputs, and `flake.nix` only declares inputs, checks, and the dev shell.
5. **Standalone Home Manager everywhere**, so the same home works on NixOS,
   macOS, and other Linux distros.
6. **Live links.** `mkSymlink` links config files into the checkout. A missing
   file fails the build.
7. **Scaffold, don't hand-write.** `bin/new` and `bin/setup` make new files.
8. **Few inputs, small helpers, plain names.**

Three modules bend rule 2 today, because a module has no other way to vary by
user or host: `claude.nix` checks the user name, `zsh.nix` calls `enableFor`,
and `git.nix` reads its signing key from the host data.
[CONFIG-006](#config-006) gives them a proper way.

## Decisions

The owner took these on 2026-11-12. Don't reopen one without a new reason.

| Topic | Decision | Task |
| --- | --- | --- |
| Aliases | Interactive shells only. Scripts and agent shells see the real commands. | [CONFIG-008](#config-008) |
| Program settings | Any program may declare settings beside `enable`. | [CONFIG-006](#config-006) |
| Git signing key | A setting of the git program, set in the user file. It leaves `config/hosts.nix`. | [CONFIG-006](#config-006) |
| User files | Two full lists. No shared profile file. | [CONFIG-004](#config-004) |
| `home/packages.nix` | One program per package. | [CONFIG-003](#config-003) |
| Programs that are off everywhere | Keep all 13 as alternatives. | [PLATFORM-003](#platform-003) |
| temis | A remote dev box, reached over Tailscale only. | [CONFIG-003](#config-003), [OPS-005](#ops-005) |
| thinkpad | Rarely used. It keeps building; its tasks are P3. | [PLATFORM-004](#platform-004) |
| framework | A Framework 16. | [PLATFORM-005](#platform-005) |
| Growth | No new users or machines expected. Multi-user work is P3. | [CONFIG-005](#config-005) |
| Homebrew on the work Mac | It works under Workbrew. | [CI-005](#ci-005) |
| Build cache | Cachix, on CI and on all four machines. | [CI-002](#ci-002) |
| Git flow | Push to `wip`, merge to `main` by hand. No PRs for your own work, no required check. | [CI-006](#ci-006) |
| Input updates | A weekly PR, merged by hand. | [CI-007](#ci-007) |
| vicinae | From nixpkgs-unstable, not from its own flake. | [CONFIG-012](#config-012) |
| Herdr mods | Track only the mods written here. Fetch the rest at a pinned revision. | [CI-004](#ci-004) |
| Backup history | At most a day old; three months back. | [OPS-001](#ops-001) |
| Backup password | Only on framework today. Store a second copy first. | [OPS-004](#ops-004) |
| Other machines | No backups for temis, thinkpad, or the Mac. | [OPS-001](#ops-001) |
| Backups and syncs | Home programs with user timers, not system timers. | [OPS-003](#ops-003) |
| Secrets | A written checklist. No sops-nix or agenix. | [OPS-004](#ops-004) |
| Top pain | Slow CI. The delivery order starts there. | [Order](#suggested-delivery-order) |
| This file | It stays one file. | — |

## Baseline

Measured on 2026-11-12. Use these numbers to judge each change.

| What | Value |
| --- | --- |
| CI, Linux `nix flake check`, warm | 23 min (1387 s), plus 98–270 s freeing disk and 203 s saving the cache |
| CI, Linux `nix flake check`, cold (after an input bump) | 62 min (3716 s); whole runs took up to 98 min |
| CI, Mac job | 4–6 min |
| CI, lint job | 22 s |
| Commits since the last input bump that changed any config derivation | 1 of 33 |
| Evaluate all seven configs (`bin/check --eval`) | 16 s on the Mac |
| List every config's derivation with one `nix eval` | 15 s for the working tree; 37 s the first time for a commit |
| Start any xonsh helper (`bin/check --help`) | 1.2 s; `nix develop` is 1.07 s of it |
| `bin/lint` | 6.7 s after a change, 0.3 s cached; the three tools run directly take 1.3 s |
| Interactive zsh start | 0.48 s; `compinit` runs twice and tops the profile |
| Non-interactive `zsh -c exit` | 0.04 s, against 0.00 s with no rc files |
| Programs on / packages, `nelson@framework` | 91 / 213 |
| Programs on / packages, `nelson@thinkpad` | 58 / 145 |
| Programs on / packages, `nelson@temis` (a server) | 59 / 146 |
| Programs on / packages, the Mac | 42 / 72 |
| Program modules | 109; 82 are 12 lines or fewer |
| Tracked files | 1,724 (11 MB); 1,430 are Herdr mods, 1,190 of those are file icons |
| Flake inputs | 10 direct, 19 lock nodes, 3 copies of nixpkgs |

## How to check a change

Four checks, cheapest first. The plans below name the ones each task needs.

**1. Lint and evaluate.** `bin/lint`, then `bin/check --eval`. Together they
take about 20 seconds and catch option, type, and assertion errors in all
seven configs.

**2. Same derivations.** A refactor should build exactly what was built
before. `bin/check --same` lists the derivation of every config at the last
commit and in the working tree, and prints each one as "same" or "changed". It
exits 0 only when all are the same, so then the refactor changed nothing.
`bin/check --same <rev>` compares with another commit, and `--why` shows what
differs in each changed derivation.

It runs one `nix eval` for each side. By hand, that is:

```shell
snapshot() {
  nix eval --json "$1#checks" --apply \
    'c: builtins.mapAttrs (_: s: builtins.mapAttrs (_: d: d.drvPath) (builtins.removeAttrs s [ "lint" ])) c' \
    | jq -S .
}
snapshot "git+file://$PWD?rev=$(git rev-parse HEAD)" > /tmp/before.json  # the last commit
snapshot . > /tmp/after.json                                              # the working tree
diff /tmp/before.json /tmp/after.json && echo "same derivations"
```

`git add` new files first, or the flake can't see them; `bin/check --same`
lists the untracked files it finds. Lint is left out because it changes with
any file.

**3. Inventory.** For changes to user files, roles, or package lists, compare
what is on:

```shell
nix eval --json '.#homeConfigurations."nelson@temis".config.dotfiles.programs' \
  --apply 'p: builtins.filter (n: p.${n}.enable) (builtins.attrNames p)'
nix eval --json '.#homeConfigurations."nelson@temis".config.home.packages' \
  --apply 'ps: builtins.sort builtins.lessThan (map (p: p.name) ps)'
```

**4. Build.** `bin/build` builds this machine's configs and prints the package
diff. It never switches. `bin/rebuild` needs a yes first.

## Priorities and scope

| Priority | Meaning | Main outcome |
| --- | --- | --- |
| P1 | Address first | Trust command results, preserve work, and recover data |
| P2 | Next | Make everyday changes faster and reduce duplication |
| P3 | Later or when needed | Extend coverage after measuring the benefit |

Slow CI is the owner's top pain, so [CI-006](#ci-006), [CI-002](#ci-002), and
[CONFIG-012](#config-012) are P1 too.

Effort is relative: **S** is a focused change, **M** spans several files and
checks, and **L** needs a migration or testing on multiple machines. These are
planning estimates, not delivery promises. Checkboxes track completed outcomes.

Each task has a topic ID, such as `CLI-001` or `CONFIG-001`. Numbering starts
at `001` within each topic:

| Prefix | Topic |
| --- | --- |
| `CLI` | Helper commands |
| `CONFIG` | Configuration model |
| `OPS` | Recovery and unattended jobs |
| `DX` | Daily development |
| `CI` | CI and maintenance |
| `PLATFORM` | Inventory, deployment, and desktop improvements |

Use these IDs in issues, commits, and progress updates. Keep an ID when a task
moves or its title changes; never renumber or reuse it. Assign new tasks the
next unused number within their topic. The explicit anchors below keep task
links stable when titles change.

Each task has **Evidence** (what is wrong today), a **Plan** (steps in order),
**Verify** (how to prove each step), and **Done when** (the outcome).

## Quick wins

Each of these is small and safe. Do them first. The first row needs no code.

| Fix | Where | Part of |
| --- | --- | --- |
| Store a second copy of the restic password and the rclone config, off the laptop. They exist only on framework, so losing it loses the backups too. | a password manager | [OPS-004](#ops-004) |
| Restore `.envrc` (`use flake`). Commit `c15fee8c` deleted it by accident, one commit after `f6bf77f6` added it. | repo root | [DX-006](#dx-006) |
| Delete `eval $(gitleaks completion zsh)`. It defines nothing and runs gitleaks in every zsh. | `git.nix` | [DX-002](#dx-002) |
| Delete the `*.init` loop. No such file is tracked, and it walks the whole checkout on every shell start. | `zshrc` | [DX-002](#dx-002) |
| Stop the second `compinit`. | `zsh.nix` | [DX-002](#dx-002) |
| Drop the `zsh-vi-mode` pin. It is fetched but never loaded. | `zsh.nix` | [DX-001](#dx-001) |
| Remove `colima.enable = enableFor [ "Remote-Nelson-Estevao" ]`. `nelson` has no home on that host, so it is never true. | `nelson.nix` | [CONFIG-010](#config-010) |
| Stop running CI twice for each commit on a PR branch. | `ci.yml` | [CI-006](#ci-006) |
| Run the 16 scaffolding tests and shellcheck in CI. Both pass today and nothing runs them. | `ci.yml` | [CI-001](#ci-001) |
| Fix the option text. It reads "Whether to enable Enable zsh configuration..". | the three module wrappers | [CONFIG-006](#config-006) |
| Fix "Agents run on the Linux machine". This review ran on the Mac. | `AGENTS.md` | [DX-007](#dx-007) |

## 1. Make helper commands dependable

<a id="cli-001"></a>

### [ ] CLI-001 Propagate command failures explicitly — P1 · M

**Evidence:** [bin/check](bin/check), [bin/rebuild](bin/rebuild),
[bin/setup](bin/setup), and [bin/update](bin/update) run commands without
saying what happens when one fails. [bin/build](bin/build) checks `returncode`
on purpose.

**Verified:** with the pinned xonsh 0.23.7, a failed command stops the script,
whether it runs plainly or inside `$()`. `bin/check --eval` exited 1 when three
configs failed. So a failed system switch already stops `bin/rebuild` before
the home switch. But this rests on a default that no script sets:

- The setting is `$XONSH_SUBPROC_RAISE_ERROR`. It was renamed: the older
  `$RAISE_SUBPROC_ERROR` is `False` here and does nothing. A xonsh upgrade can
  change the behavior without a word.
- The shebangs don't pass `--no-rc`, so a user's rc file can change it too.
- A failure prints a Python `CalledProcessError`, not which step failed.
- `bin/build` and `bin/rebuild` replace `NIX_CONFIG`. That drops anything
  already in it, such as an access token.

**Plan:**

1. Add `scripts/common.xsh`. It sets `$XONSH_SUBPROC_RAISE_ERROR = True`,
   hides tracebacks, and gives `fail(message)`, the repo root, and colors that
   are empty when there is no terminal. Import it in every xonsh helper, the
   way `bin/new` imports `scaffold`. This also removes the color tables that
   three scripts repeat twice each.
2. Add `--no-rc` to the six xonsh shebangs and to the scripting convention.
3. Name the step that failed: "✗ nh os switch failed; home was not switched".
4. Append to `NIX_CONFIG` instead of replacing it.
5. Add tests that put stub `nh`, `nix`, and `git` commands on `PATH` (the
   `fake()` helper in [tests/test_scaffolding.py](tests/test_scaffolding.py)
   does this) and check the exit status and which commands ran.

**Verify:**

- With a stub `nh` that exits 1, `bin/rebuild` exits non-zero and the stub's
  log shows no `home switch`.
- With a stub `nix` that exits 1, `bin/check` and `bin/update --save` exit
  non-zero and make no commit.
- `NIX_CONFIG='access-tokens = x' bin/build` passes both settings to the stub.
- Bump xonsh on a branch: the tests pass, or they fail and say why.

**Done when:** stub commands returning failure exercise each branch, the helper
returns failure, and no dependent mutation runs. Keep the deliberate behavior
in `bin/build` that attempts both builds and reports aggregate failure.

<a id="cli-002"></a>

### [ ] CLI-002 Make updates selective and commits isolated — P1 · M

**Evidence:** [bin/update](bin/update) always updates all inputs, parses Nix's
human-readable output with five regular expressions, then runs an unrestricted
`git commit` after staging `flake.lock`. Any unrelated changes already staged
can enter that commit. It runs `tput` 20 times at start, which fails without a
terminal.

**Plan:**

1. Take input names: `bin/update [<input>...]` runs
   `nix flake update <input>...`.
2. Read `flake.lock` as JSON before and after. Build the summary from the two
   files: revision, date, added and removed inputs, and changed `follows`.
   Delete the regular expressions.
3. Stop early when `flake.lock` already has an uncommitted edit, and say so.
4. Commit only the lock file: `git commit -m … -- flake.lock`. Git then leaves
   other staged files staged and out of the commit.
5. Add `--check`: run `bin/check --eval` before saving.
6. Use colors and the spinner only with a terminal (from `scripts/common.xsh`,
   see [CLI-001](#cli-001)).

**Verify:**

- Fixture repos cover: nothing to update, one input changed, a failed update,
  no terminal, and a dirty index.
- With an unrelated file staged, `bin/update --save` then
  `git show --stat HEAD` lists only `flake.lock`, and
  `git diff --cached --stat` still lists the other file.
- `bin/update nixpkgs` changes only the nixpkgs node in the lock.

**Done when:** fixtures cover no-op updates, changed inputs, update failures,
nonterminal use, and a dirty index; unrelated files never enter the upgrade
commit. Existing approval rules for updates and commits remain in force.

<a id="cli-003"></a>

### [ ] CLI-003 Resolve targets from host data — P2 · M

**Evidence:** [bin/build](bin/build) and [bin/rebuild](bin/rebuild) choose the OS
command from `sys.platform` and default to both OS and home. The README already
documents that the default rebuild fails on a Home Manager-only host.

**Plan:**

1. Read the host data once: `nix eval --json --file config/hosts.nix`.
2. Find this machine's entry by host name. If it is missing, stop and list the
   known names.
3. Default to what the host has: `os` only with a `platform`, `home` always.
   Plain `bin/rebuild` on thinkpad then switches the home only.
4. Add `--host` and `--user` to `bin/build`, to build another config.
5. Reject `--boot` unless the target is a NixOS system.
6. Print the target before a switch: "Switching nixosConfigurations.framework
   and nelson@framework".

**Verify:**

- Routing tests with stub `nh` and `hostname` for all four hosts.
- `bin/rebuild os` on thinkpad exits non-zero before `nh` runs.
- `bin/rebuild home --boot` is an error, not ignored.

**Done when:** framework, temis, thinkpad, and the Mac select the expected
outputs in command-routing tests. An explicit OS request on thinkpad fails
before invoking a system builder.

<a id="cli-004"></a>

### [x] CLI-004 Separate native builds from evaluation of all systems — P1 · S

**Implemented:** plain `bin/check` runs two commands. First
`nix flake check --all-systems --no-build`, which evaluates every config on
every system, as `bin/check --eval` does. Then `nix flake check`, which builds
this machine's system only. So it still reads the other OS's configs, and it
no longer needs a builder for them. `bin/check --eval` is unchanged.
`bin/check --all-systems` is the explicit way to build the other OS, and its
help says it needs a builder for it. The README and AGENTS.md say what each
one covers, and that evaluating a config does not test activation on the other
OS.

Checked on the Mac: plain `bin/check` passed in 20 seconds. It evaluated all
seven configs, built only the `aarch64-darwin` checks, and reported "omitted
these incompatible systems: x86_64-linux" for the build. `bin/check --eval`
still listed all seven configs. Tests in
[tests/test_check.py](tests/test_check.py) pin the commands each flag runs,
and that a failed evaluation stops before the build. The Linux side was not
run by hand: its build step is the same `nix flake check` that the Linux CI
job already runs with no Mac builder.

**Original evidence:** [bin/check](bin/check) always passed `--all-systems`,
including when building. [CI](.github/workflows/ci.yml) instead builds native
checks on separate Linux and Mac runners. On the Mac, plain `bin/check` asked
Nix to build the three Linux home configs, which needs a Linux builder.

**Plan:**

1. `bin/check` runs `nix flake check`: this machine's system only, like each
   CI runner.
2. `bin/check --eval` stays as it is: every system, nothing built.
3. `bin/check --all-systems` is the explicit way to build foreign systems. Its
   help says it needs a builder for the other OS.
4. Update the README table and AGENTS.md. Say that evaluating the Mac config
   on Linux does not test activation on macOS.

**Verify:**

- On Linux with no Mac builder, `bin/check` passes.
- `bin/check --eval` still lists all seven configs.

**Done when:** a Linux user can run the default check without a Darwin builder;
the evaluation command still covers every declared configuration; local and CI
coverage are documented accurately.

<a id="cli-005"></a>

### [x] CLI-005 Make scaffolding validate before writing — P1 · M

**Implemented:** `bin/new` and `bin/setup` validate names and rendered Nix before
writing, escape Nix strings, check host inputs, preserve existing staged edits,
and restore changed files on write/staging failure. Hardware detection requires
`--detect-hardware`; stubs print filesystem and boot-loader next steps. The
README documents the workflow. All 16 scaffolding regression tests, `bin/lint`,
`bin/format`, and `bin/check --eval` passed. No live system was switched.

**Follow-up:** CI does not run these tests yet. See [CI-001](#ci-001).

**Original evidence:** [bin/new](bin/new) inserts names into paths and Nix templates.
[bin/setup](bin/setup) interpolates strings directly, locates configuration
entries with regular expressions, accepts platform and architecture separately,
and writes several files before final validation. Setup templates also contain
unused arguments that the lint policy can reject.

Validate names against path traversal, separators, and unsupported identifiers.
Escape Nix strings, including quotes, backslashes, and interpolation syntax.
Validate platform/architecture pairs and user references before creating files.
Render and validate proposed changes in a temporary location, then apply them
together. Preserve unrelated edits in `config/` and its staged contents.
Keep deliberate hardware stubs, but finish with precise instructions to supply
filesystems and a boot loader before evaluation or rebuilding.

**Done when:** generated complete examples pass lint; malformed input leaves no
partial files; names and display strings with punctuation behave predictably;
hardware stubs are clearly reported as incomplete. Hardware detection should
be an explicit choice, not inferred solely from having a terminal.

<a id="cli-006"></a>

### [ ] CLI-006 Add a same-derivation check — P1 · S

**Evidence:** most plans in this file say "prove nothing changed". There is no
command for that. **Verified:** one `nix eval` lists the derivation of all
seven configs in 15 seconds (see [How to check a change](#how-to-check-a-change)).
`HEAD~1` and `HEAD` gave the same list, and so did a wrapper change tried in a
scratch clone ([CONFIG-006](#config-006)).

**Progress:** steps 1 to 3 are done. `bin/check --same [<rev>] [--why]`
exists, `nix-diff` is in the dev shell (it is prebuilt for both systems), and
the README and AGENTS.md describe it. Beyond the plan, it:

- reports a config that exists on one side only as "added" or "removed";
- fails when there is nothing to compare, and on an unknown revision;
- lists untracked files of any type, since the flake reads more than `.nix`;
- evaluates both sides at once and prints the warnings Nix gave for each;
- compares the system derivations for the eval-only `nixos-<host>` and
  `darwin-<host>` checks, so `--why` shows the real difference;
- works in a shallow clone.

Fifteen tests in [tests/test_check.py](tests/test_check.py) cover it with a
stand-in `nix`.

Checked on the Mac, from a git worktree: a clean tree and a comment-only edit
showed all seven as "same" and exited 0. Adding `hello` to
`home/programs/curl/curl.nix` changed the four home configs that enable curl
and neither system config, exited 1, and `--why` named `hello-2.12.3`. Adding
a UDP port in `system/hosts/framework.nix` changed only `nixos-framework`,
and `--why` showed the new firewall rule. A run takes about 24 seconds, against
33 with one evaluation after the other, on a busy machine.

Left to do: step 4, in [CI-006](#ci-006). The `fail` helper and the colors in
`bin/check` should move to the shared file that [CLI-001](#cli-001) adds.

**Plan:**

1. Add `bin/check --same [<rev>]`. It lists the derivations at `<rev>`
   (default `HEAD`) and in the working tree, and prints each config as "same"
   or "changed". It exits 0 only when all are the same.
2. Add `--why`: run `nix-diff` on each changed pair and print what differs.
   Add `nix-diff` to the dev shell.
3. Document it in the README table and in AGENTS.md under "Check your work":
   a refactor must show "same".
4. Reuse the same expression in CI ([CI-006](#ci-006)).

**Verify:**

- Change a comment: all seven are the same.
- Add a package to one program: only the configs that enable it change, and
  `--why` names the package.
- An untracked new file gives a clear hint to `git add` it.

**Done when:** the refactors below use it, and an agent can prove "no config
changed" with one command.

## 2. Validate the model and simplify configuration

<a id="config-001"></a>

### [ ] CONFIG-001 Validate every host and user entry centrally — P1 · M

**Evidence:** [lib/default.nix](lib/default.nix) checks state-version presence
and role/name collisions, and nothing else. **Verified** in a scratch clone:

| Mistake in `config/hosts.nix` | What happens today |
| --- | --- |
| `platform = "nixoss"` on temis | No error. temis leaves `nixosConfigurations`; its home still builds. |
| `rolse = [ "desktop" ]` on framework | No error. Every desktop program turns off. |
| `users = [ "nelsno" ]` | `error: attribute 'nelsno' missing`, with no file or host named. |
| `system = "x86-64-linux"` | `error: attribute 'x86-64-linux' missing`. |

The second row breaks the promise that a typo can't quietly turn a program
off.

**Verified** fix: a 34-line schema, checked by `lib.evalModules`, catches all
four with the host and field named. Two of its messages:

```
error: The option `hosts.framework.rolse' does not exist. Definition values:
- In `config/hosts.nix':
    [
      "desktop"
    ]

Did you mean `hosts.framework.roles', `hosts.framework.git' or `hosts.framework.system'?
```

```
error: A definition for option `hosts.temis.platform' is not of type `null or one of "nixos", "darwin"'. Definition values:
- In `config/hosts.nix': "nixoss"
```

**Plan:**

1. Add `lib/schema.nix`. Hosts: `system` (one of four), `platform` (`null`,
   `"nixos"`, or `"darwin"`), `roles`, `users` (a non-empty list of known user
   names), `stateVersion`, and `darwinStateVersion`. Users: `name`,
   `extraGroups`, `extraSpecialArgs`. Give each option a description. The
   `git.*` fields leave the host data in [CONFIG-006](#config-006); if the
   schema lands first, include them until then.
2. Run both data files through it in `lib/default.nix`. Force every field with
   `builtins.deepSeq`, or a lazy field hides its error.
3. Add the rules that span fields, as one list of named checks: the platform
   matches the system's OS, a Mac has `darwinStateVersion`, no role shares a
   host's name, no user is listed twice, and `home/users/<user>.nix` and
   `system/hosts/<host>.nix` exist.
4. Delete `normalizePlatform`, `checkHost`, and the loose platform matching.
   The schema replaces them.
5. Stop `extraSpecialArgs` from replacing `host`, `hostname`, `username`,
   `user`, `enableFor`, or `disableFor` in
   [mkHomeConfig](lib/mkHomeConfig.nix).
6. Keep the data files as plain attribute sets, so `bin/setup` can still read
   and write them.

**Verify:**

- Each row of the table fails `bin/check --eval` with the host and the field
  in the message.
- `bin/check --same` reports "same" for the real data.
- The scaffolding tests still pass.

**Done when:** invalid fixtures fail with the field and host/user name, even
when an output filter would otherwise hide them. Existing state versions stay
unchanged.

<a id="config-002"></a>

### [ ] CONFIG-002 Add focused regression tests for the shared helpers — P1 · M

**Evidence:** the flake evaluates real configurations, but does not declare
dedicated tests for [role selection](home/lib/enableFor.nix),
[module discovery](lib/importModules.nix), or
[module wrappers](home/lib/mkHomeModule.nix). The real hosts only test the
combinations that happen to exist.

**Plan:**

1. Add `tests/lib.nix` with `lib.runTests`. It ships with nixpkgs, so it needs
   no new input. Wrap cases that must fail in `builtins.tryEval`.
2. Cover the pure helpers: `enableFor` and `disableFor` with a host, a role, a
   mix, and an unknown name; the OS role; a role that shares a host's name;
   and each row of the [CONFIG-001](#config-001) table.
3. Cover the wrappers with a tiny home config built from fixture programs in
   `tests/fixtures/`: a wrong-OS program fails with the host's name, a
   disabled program adds nothing, a missing link source fails, and a folder
   with no `<name>.nix` gives a clear error.
4. Expose it as `checks.<system>.lib-tests`: a derivation that fails when the
   list of failures is not empty. The work happens at evaluation, so
   `bin/check --eval` runs the tests.
5. Decide how a folder opts out of discovery. A leading `_` is the common
   convention. Test it.

**Verify:**

- Break `enableFor` on purpose (make it need every name): the check fails and
  names the case.
- `bin/check --eval` gets less than 5 seconds slower.
- No test builds a package or touches the real home.

**Done when:** the checks catch the known failure cases without building a
desktop closure or touching the real home. Avoid snapshotting entire generated
configurations or testing trivial package declarations.

**Note:** `nix-unit` reports failures better and is in nixpkgs. Inside the Nix
sandbox it needs its own eval store and an override for each input. Start with
`lib.runTests`; move if the output is not good enough.

<a id="config-003"></a>

### [ ] CONFIG-003 Reduce the server and base-home package sets — P2 · M

**Evidence:** [nelson.nix](home/users/nelson.nix) enables Flutter, Haskell, media
tools, and many language modules everywhere. **Measured:** temis, a server,
gets 59 programs and 146 packages, among them Flutter, GHC, ffmpeg,
ImageMagick, and unoconv.

[home/packages.nix](home/packages.nix) puts 37 packages behind one flag,
`dotfiles.packages.enable`. It is the one place where a program is not an
option. Some of them are Linux-only, such as `gvfs`, `fuse`, `appimage-run`,
and `impression`. The Mac user file has the flag commented out, so the Mac
gets none of the 37.

[home/scripts.nix](home/scripts.nix) rides the same flag. `hm-diff` uses GNU
`stat` and `date`, `nixos-diff` is installed on hosts that are not NixOS, and
`wake-hades` has one machine's MAC address in it.

**Decided:** one program per package. temis is a remote dev box, so it keeps
the language toolchains and loses what only a desktop needs.

**Plan:**

1. Save the inventory and the sorted package list of every config
   ([How to check a change](#how-to-check-a-change)). On framework, save the
   closure size: `nix path-info -Sh ~/.local/state/nix/profiles/home-manager`.
2. Make one program for each of the 37 packages with `bin/new program <name>`.
   Mark the Linux-only ones with `platforms`.
3. Make one program for each script too: `pkgversion`, `gensecret`, `hm-diff`
   (with portable `stat` and `date` calls), and `wake-hades`, whose address
   becomes a setting ([CONFIG-006](#config-006)). `nixos-diff` becomes a
   NixOS module.
4. Add the new lines to `nelson.nix`, so each config gets what it had. Use
   `enableFor [ "desktop" ]` for the ones a server has no use for, such as
   `mpv` and `impression`.
5. Delete `dotfiles.packages`, `home/packages.nix`, `home/scripts.nix`, and
   the flag in the user files and in the user template in `bin/setup`.
6. Turn on, in the Mac user file, the ones wanted there.
7. Trim temis. Review Flutter and the media and document tools (ffmpeg,
   ImageMagick, exiftool, unoconv, pandoc, typst). Keep what you use over
   SSH.
8. Save the numbers again.

**Verify:**

- After steps 2–5, the sorted package list of framework is the same as
  before.
- After steps 4 and 7, the inventory of temis and thinkpad shows only the
  removals you meant.
- The Mac evaluates with its new lines, and `bin/build home` there shows only
  the packages you added.
- The count of program folders goes from 109 to about 150.

**Done when:** record closure size and package count before and after; temis has
an intentional server toolset; the portable base evaluates on Linux and Darwin.
Do not remove tools solely because two packages overlap.

<a id="config-004"></a>

### [ ] CONFIG-004 Keep user files explicit and role-based — P2 · S

**Evidence:** [the two user files](home/users) share 34 identical
`… .enable = true;` lines. **Decided:** they stay as two full lists, so each
file shows everything its user gets. There is no shared profile file.

What is left to fix:

- Some choices use a host name where the reason is the OS: `cmux` is
  `enableFor [ "Remote-Nelson-Estevao" ]`, and `aerospace` and `colima` are
  plain `true` in a file that could one day serve a Linux host.
- `enableFor [ "desktop" "linux" ]` means desktop **or** Linux. "Both" already
  works, because the helpers return plain booleans, but no doc says so:

  ```nix
  dotfiles.programs.gnome.enable = enableFor [ "desktop" ] && enableFor [ "linux" ];
  dotfiles.programs.zed.enable = enableFor [ "desktop" ] && disableFor [ "temis" ];
  ```

**Plan:**

1. Use roles where the reason is the OS: `enableFor [ "darwin" ]` for cmux,
   aerospace, and colima.
2. Make `gnome`, `vicinae`, and the other Linux desktop programs in
   `nelson.nix` say both conditions, as above.
3. Document `&&` and `disableFor` in the README, next to the `enableFor`
   examples.
4. Keep both files in the same order with the same section comments, so a
   `diff` of the two shows what differs.

**Verify:**

- The inventory of all four configs is the same before and after.
- `bin/check --same` reports "same".
- A fixture Mac host with the `desktop` role and user `nelson` evaluates.
  Today it stops with the wrong-OS error, because `gnome` turns on there.

**Done when:** overrides remain obvious, and a Mac desktop cannot accidentally
enable Linux desktop modules.

<a id="config-005"></a>

### [ ] CONFIG-005 Move Mac deployment facts out of shared modules — P3 · M

**Evidence:** [system/darwin.nix](system/darwin.nix) disables Nix management for
every Mac and derives the primary user alphabetically. It also sets the Dock
and Finder defaults, so NixOS has 16 system modules and the Mac has one.
[The Homebrew module](system/modules/darwin/homebrew/homebrew.nix) hardcodes
Workbrew paths, completion workarounds, and one person's apps. The README tells
another Mac user to edit that shared module.

**Decided:** no new users or Macs are expected, and the Homebrew step works
under Workbrew today. So this waits until a second Mac shows up.

**Plan:**

1. Add host fields, checked by the schema ([CONFIG-001](#config-001)):
   `primaryUser`, which must be one of the host's users, and who manages Nix.
2. Give the Homebrew module settings ([CONFIG-006](#config-006)): `prefix`,
   `taps`, `brews`, and `casks`. The Mac's host file sets them. Apply the
   Workbrew `fpath` fix only when the prefix is Workbrew's.
3. Move the Dock and Finder defaults into `system/modules/darwin/dock` and
   `finder` with `bin/new module <name> --darwin`. Turn them on in the host
   file.
4. Cut the README section on using the Homebrew module down to "set these in
   your host file".

**Verify:**

- `bin/check --same` reports the Mac system as "same" after each step.
- A fixture Mac with no Workbrew and another primary user evaluates.
- On the Mac, `bin/build os` shows no package change. Ask before
  `bin/rebuild`.

**Done when:** the existing Mac retains its behavior, a normal Mac can be added
without editing shared implementation, and an explicit primary user must belong
to the host. Evaluate fixtures on Linux and test activation on the actual Mac.

<a id="config-006"></a>

### [ ] CONFIG-006 Let a program declare its own settings — P2 · S

**Progress (2026-11-12):** steps 1–5, 7, and 8 are done on the branch
`home/program-settings`.

- The three wrappers take `options` and the option text is fixed. One helper,
  `mkSymlinkIn` in [home/lib](home/lib/default.nix), serves the home and
  GNOME wrappers.
- Converted: zsh `showHost`, claude `skills`, the two GNOME lists (now in
  `gnome.nix`), and the git signing key, which left `config/hosts.nix`.
- Checked: all seven configs build the same derivations as before, and the
  generated git config of each home is byte for byte the same. `showHots`
  stops the build with "The option `dotfiles.programs.zsh.showHots' does not
  exist" and a "Did you mean" hint. A program made by `bin/new` with a setting
  of its own evaluates. The 16 scaffolding tests, `bin/lint`, and
  `bin/check --eval` pass.

Left: the fixture test (step 9) waits for [CONFIG-002](#config-002). Printing
and Homebrew wait for [CONFIG-005](#config-005). `valueFor` (step 6) is not
needed yet: one `if` covers the signing key.

**Evidence** (how it was before): the wrappers declared one option, `enable`.
A program had no way to offer a setting that a user or a host can change, so
modules reached around the rules:

- [claude.nix](home/programs/claude/claude.nix) linked skills only when
  `username == "nelson"`.
- [zsh.nix](home/programs/zsh/zsh.nix) called `enableFor [ "server" ]` itself.
- [git.nix](home/programs/git/git.nix) read `host.git.signingKey`, so
  `config/hosts.nix` held a fact about one program.
- `home/programs/gnome/options.nix` was imported by hand in
  [home/default.nix](home/default.nix).
- The printing module names one printer. The Homebrew module names one
  person's apps.

**Verified** in a scratch clone: a ten-line change to
[mkHomeModule](home/lib/mkHomeModule.nix) lets a program declare typed settings
next to its config. All seven configs built the same derivations, and a
misspelled setting failed by name:

```nix
# home/programs/zsh/zsh.nix
{
  options.showHost = lib.mkEnableOption "the host name in the prompt";

  home.sessionVariables.PROMPT_SHOW_HOST = lib.mkIf config.dotfiles.programs.zsh.showHost "1";
}

# home/users/nelson.nix
dotfiles.programs.zsh.showHost = enableFor [ "server" ];
```

```
error: The option `dotfiles.programs.zsh.showHots' does not exist.
```

This is the same idea as `enable`, one step further: the program offers, the
user file picks, and `enableFor` handles the exceptions.

**Decided:** any program may declare settings, and the git signing key
becomes one of them.

**Plan:**

1. In `mkHomeModule`, add `result.options or { }` beside `enable`, and leave
   `options` out of the settings. Do the same in
   [mkSystemModule](system/lib/mkSystemModule.nix) and
   [mkGnomeExtensionModule](home/lib/mkGnomeExtensionModule.nix).
2. Fix the option text: `lib.mkEnableOption "the ${name} program"`.
3. Share one `mkSymlink` between the home and GNOME wrappers. They carry the
   same code twice.
4. Convert the cases above: zsh `showHost`, claude `skills`, and the GNOME
   options into `gnome.nix`. Printing and Homebrew wait for
   [CONFIG-005](#config-005).
5. Move the git signing key. `git.nix` declares `signingKey` and
   `signingProgram`, the user files set them, and `config/hosts.nix` loses
   its `git.*` fields:

   ```nix
   # home/users/nelson.nix
   dotfiles.programs.git.signingKey =
     if enableFor [ "temis" ] then "~/.ssh/id_ed25519.pub" else "ssh-ed25519 AAAA…N8b6";
   ```

6. If such `if` chains grow, add a `valueFor` helper beside `enableFor`. It
   picks a value by host name or role, with the same typo check. A host name
   beats a role, and a role beats `default`. Two roles that match with
   different values are an error. This is a sketch; it has not been tried:

   ```nix
   dotfiles.programs.git.signingKey = valueFor {
     temis = "~/.ssh/id_ed25519.pub";
     default = "ssh-ed25519 AAAA…N8b6";
   };
   ```

7. Add a commented example to the program template in `bin/new`.
8. Document it in the README under "How modules work". State the one rule: a
   program that declares settings must return a plain attribute set. If the
   whole body sits inside `lib.mkIf` or `if`, evaluation loops.
9. Add a fixture with a setting to the tests ([CONFIG-002](#config-002)).

**Verify:**

- `bin/check --same` reports "same" after each of steps 1–5.
- `grep -rnE --include='*.nix' 'username ==|hostname ==|enableFor \[|host\.[a-zA-Z]' home/programs system/modules`
  finds nothing.
- `grep -n git config/hosts.nix` finds nothing.
- A misspelled setting fails with its name.

**Done when:** no module checks a user or host name, and a new setting needs
one line in the program and one in the user or host file.

<a id="config-007"></a>

### [ ] CONFIG-007 Keep program names out of `lib/` — P3 · S

**Evidence:** `vicinae` is passed by name through [flake.nix](flake.nix),
[lib/default.nix](lib/default.nix), [mkHomeConfig](lib/mkHomeConfig.nix), and
[mkNixosConfig](lib/mkNixosConfig.nix), which also holds the switch for its
input server. AGENTS.md says a new input needs `flake.nix` and
`config/overlays.nix`. An input that brings a module needs five files.

**Decided:** vicinae moves to nixpkgs ([CONFIG-012](#config-012)). That
removes every line named above. What stays is the gap: an input that ships a
module has no home in `config/`. The next one is `nixos-hardware`
([PLATFORM-005](#platform-005)), and it is for one host only.

**Plan:**

1. Do [CONFIG-012](#config-012) first.
2. When the next input with a module arrives, add `config/modules.nix`, next
   to `overlays.nix`. It lists modules for every home, every NixOS host,
   every Mac, and for single hosts by name.
3. Make the builders take those lists. No input is passed to `lib/` by name.
4. Update AGENTS.md and the README section "Using another flake".

**Verify:**

- `bin/check --same` reports "same" for the hosts the new module does not
  touch.
- `grep -rnE 'vicinae|nixos-hardware' lib/` finds nothing.

**Done when:** adding a flake that ships a module touches `flake.nix` and
`config/`, and nothing in `lib/`.

<a id="config-008"></a>

### [ ] CONFIG-008 Make shell hooks shell-neutral — P2 · S

**Evidence:** nine modules write to `programs.zsh.envExtra`, eight of them
behind `lib.mkIf config.dotfiles.programs.zsh.enable`. The program template in
`bin/new` teaches the same. `envExtra` lands in `~/.zshenv`, which every zsh
reads, scripts included.

**Verified** on the Mac: `zsh -c 'cat --version'` prints `bat 0.26.1`. Any
script or tool that runs through zsh gets `bat -p` when it asks for `cat`, plus
`j`, `lg`, `mr`, and `pj`. The fzf key bindings load there too.

**Decided:** aliases belong to interactive shells only.

**Plan:**

1. Move aliases to `home.shellAliases`. Home Manager writes them into each
   enabled shell's interactive config.
2. Move `PATH` lines to `home.sessionPath`, and interactive setup such as the
   fzf bindings to `programs.zsh.initContent`.
3. Drop the `lib.mkIf config.dotfiles.programs.zsh.enable` guards that are no
   longer needed.
4. Update the comment in the `bin/new` template.

**Verify:**

- `zsh -c alias` prints no alias from this repo.
- `zsh -ic alias | sort` prints the same list as before.
- `zsh -c 'cat --version'` is the real `cat`.
- `~/.mix/escripts` is in `PATH` once in a new shell.

**Done when:** a program adds an alias with one line that names no shell, and
scripts see the real commands.

<a id="config-009"></a>

### [ ] CONFIG-009 Expose custom packages and let overrides expire — P2 · M

**Evidence:** four programs build their own package (`git-sim`,
`projectionist`, `glocalsend`, `rudra`). Five more places override one: the
herdr-app patch, the wiggle fork, the cmux bump, weasyprint's tests on the Mac,
and six pinned zsh plugins. None is a flake output, so:

- `nix build .#git-sim` does not work.
- CI builds them only inside a full home build.
- Nothing says when nixpkgs catches up and an override can go.

Today nixpkgs has git-sim 0.3.5 (ours is 0.4.0) and cmux 0.64.22 (ours is
0.65.2.2). herdr-app is 0.1.11 with a patch that upstream merged after 0.1.12.

**Plan:**

1. Add `lib/packages.nix`. It finds every `package.nix` under
   `home/programs/` and returns `packages.<system>.<name>`, limited to the
   systems each package supports. The modules keep calling the file next to
   them.
2. Add the overridden packages (herdr-app, wiggle, cmux), so CI can build each
   one alone.
3. Make each override say when to delete it:

   ```nix
   herdr-app = prev.lib.warnIf (prev.lib.versionAtLeast prev.herdr-app.version "0.1.13")
     "herdr-app has the focus-ring fix now: drop the patch in config/overlays.nix"
     (prev.herdr-app.overrideAttrs …);
   ```

   Do the same for git-sim, cmux, and wiggle.
4. Add `nix-update` to the dev shell and `bin/update --packages`, which runs
   `nix-update --flake <name>` for each package fetched from GitHub.
5. Build `packages` in CI, kept in the cache ([CI-002](#ci-002)).

**Verify:**

- `nix build .#projectionist` works on the Mac and on Linux.
- `nix flake show` lists the packages.
- Lower a version limit in a scratch clone: `bin/check --eval` prints the
  warning.
- `bin/check --same` reports "same" for the seven configs.

**Done when:** every custom package builds alone, and an out-of-date override
warns on the next evaluation.

<a id="config-010"></a>

### [ ] CONFIG-010 Catch selectors that can never be true — P2 · S

**Progress (2026-11-12):** steps 1 and 2 are done on the branch
`home/program-settings`. `enableFor` and `disableFor` know which hosts list
the user. The old line now stops the build with "nelson has no home on
Remote-Nelson-Estevao (homes: framework, temis, thinkpad)". `colima` in
`nelson.nix` is `enableFor [ "darwin" ]`. All seven configs build the same
derivations as before.

Left: the two test cases (step 3) wait for [CONFIG-002](#config-002).

**Evidence** (how it was before): [nelson.nix](home/users/nelson.nix) had
`colima.enable = enableFor [ "Remote-Nelson-Estevao" ]`. **Verified:** `nelson`
is not a user on that host, so the line was never true. `enableFor` accepted
it because the name is a known host.

**Plan:**

1. Tell `enableFor` which hosts list this user. A host name the user has no
   home on is an error: "nelson has no home on Remote-Nelson-Estevao (homes:
   framework, temis, thinkpad)". Roles stay open, so a user file can plan for
   a role it has no host for yet.
2. Fix the line in `nelson.nix`: delete it, or use `enableFor [ "darwin" ]`.
3. Add both cases to the tests ([CONFIG-002](#config-002)).

**Verify:**

- Put the line back: `bin/check --eval` fails and names the user and host.
- The inventory of all four configs is unchanged.

**Done when:** a selector that names a host the user is not on stops the
build.

<a id="config-011"></a>

### [ ] CONFIG-011 Share one nixpkgs per system — P3 · M

**Evidence:** each of the seven configs imports nixpkgs for itself, with the
same overlays, and `allowUnfree` is set in three files. The `unstable` overlay
imports a second nixpkgs each time. Standalone Home Manager imports nixpkgs
again even when it is handed a `pkgs`, so sharing needs
`_module.args.pkgs = lib.mkForce …` (read in its source, not tried). The gain
only shows inside one Nix process, and evaluating everything takes 16 seconds
today.

**Plan:**

1. Measure `nix flake check --no-build --all-systems`: time, and peak memory
   with `/usr/bin/time -l`.
2. Try a `pkgsFor.<system>` in a scratch clone and measure again.
3. Adopt it only if it saves more than a third. If not, close this task as
   "measured, not worth it".

**Verify:** `bin/check --same` reports "same", and both sets of numbers are
written here.

**Done when:** the numbers are recorded and the decision is made.

<a id="config-012"></a>

### [ ] CONFIG-012 Take vicinae from nixpkgs — P1 · S

**Evidence:** vicinae comes from its own flake, built against
nixpkgs-unstable. No cache has that build, so every bump costs about an hour
in CI and again on the laptop. The flake also brings four more lock nodes
(`numen`, `soulver-cpp`, a nixpkgs 24.11 pin, `systems`), an overlay entry,
and wiring in three `lib/` files ([CONFIG-007](#config-007)).

**Verified:**

- nixpkgs-unstable has vicinae 0.29.2, prebuilt in `cache.nixos.org`. The
  flake gives 0.30.0.
- That package ships `libexec/vicinae/vicinae-input-server`.
- The pinned Home Manager has its own `programs.vicinae` module: `enable`,
  `package`, `systemd`, `useLayerShell`, `settings`, `themes`, `extensions`.
  The flake's module turns it off to use its own.
- nixpkgs has no NixOS module for vicinae. The flake's one is six lines: a
  security wrapper that gives the input server one capability. Clipboard and
  emoji pasting and snippets need it.

**Decided:** use the nixpkgs package.

**Plan:**

1. Pick the moment. Going from 0.30.0 to 0.29.2 is a step back, and vicinae
   may not read newer data. Either wait until `pkgs.unstable.vicinae` is at
   least the installed version, or back up `~/.config/vicinae` and its data
   folder first.
2. Home side: set `package = pkgs.unstable.vicinae` and
   `useLayerShell = true` in [vicinae.nix](home/programs/vicinae/vicinae.nix),
   and drop `systemd.environment`. Home Manager's own module takes over.
3. System side: put the wrapper in
   [the vicinae system module](system/modules/nixos/vicinae/vicinae.nix),
   which is an empty body today:

   ```nix
   security.wrappers.vicinae-input-server = {
     source = "${pkgs.unstable.vicinae}/libexec/vicinae/vicinae-input-server";
     capabilities = "cap_dac_override+ep";
     owner = "root";
     group = "root";
   };
   ```

4. Remove the `vicinae` input, its overlay entry, its arguments in
   `flake.nix` and `lib/`, and its line in CI's "Keep the slow builds" step.

**Verify:**

- `bin/check --eval` passes, and `grep -rn vicinae flake.nix lib/` finds
  nothing.
- `flake.lock` has five nodes fewer.
- On framework, `bin/build` downloads vicinae and compiles nothing.
- After the switch: the launcher opens with Alt+Space, a clipboard entry
  pastes, and `getcap /run/wrappers/bin/vicinae-input-server` shows the
  capability.

**Done when:** no machine and no CI run builds vicinae from source.

## 3. Make recovery and unattended jobs trustworthy

Nothing in this section was run. The plans come from the source.

<a id="ops-001"></a>

### [ ] OPS-001 Define backup retention, verification, and restore drills — P1 · M

**Evidence:** [system/timers/nelson.nix](system/timers/nelson.nix) defines three
Restic repositories and backup paths, but no explicit retention policy,
repository checks, restore drill, or failure notification. Only framework
enables these timers in the current host files.

**Plan:**

1. Store the second copy of the password first ([OPS-004](#ops-004), step 1).
2. Write the recovery scope in the README. **Decided:** only framework is
   backed up. temis, thinkpad, and the Mac hold nothing that is not in git or
   on framework, so unpushed work there is at risk by choice.
3. Add retention. **Decided:** at most a day old, three months back:
   `pruneOpts = [ "--keep-daily 7" "--keep-weekly 4" "--keep-monthly 3" ]`.
   Review this as its own change; it deletes data.
4. Add a weekly check: `checkOpts = [ "--read-data-subset=5%" ]`.
5. Report failures: an `OnFailure=` unit that sends a desktop notification,
   and a line in the shell greeting when the newest snapshot is more than two
   days old.
6. Run a restore drill and record it here: restore one folder to `/tmp`,
   compare it with the original, and write the date and result.

**Verify:**

- `restic-mega snapshots --latest 1` shows a snapshot newer than a day on a
  workday.
- `restic-mega restore latest --target /tmp/drill --include ~/Documents/<x>`,
  then `diff -r` shows no difference.
- Stop the network and start the service: the failure notice appears.

**Done when:** a restore drill has a recorded date and result, backup age is
visible, and each host has an explicit backup decision. Treat deletion/pruning
policy as a reviewed change, not an incidental optimization.

<a id="ops-002"></a>

### [ ] OPS-002 Spread backup work and inspect exclusions — P2 · M

**Evidence:** all three repositories start at `Mon..Fri 17:00`, scan the same
paths, and use maximum compression. [exclude.txt](home/programs/restic/exclude.txt)
contains a large set of development exclusions.

**Plan:**

1. Measure a week first: start, end, and bytes sent, from
   `journalctl -u restic-backups-<name>`.
2. Stagger the starts (17:00, 17:30, 18:00) or chain the units, and add
   `RandomizedDelaySec`.
3. Compare `--compression=max` with `auto` on one repository: time against
   size.
4. Dry-run the exclusions:
   `restic backup --dry-run --verbose=2 … | grep -c '^new'`, then look for
   source you would miss.
5. Retry with a limit when the network is down, and skip on battery if that
   matters.

**Verify:**

- No two backup services overlap in `systemctl list-timers` and the journal.
- A dry run lists a known untracked source folder as included.
- A restore of one excluded and one included path behaves as expected.

**Done when:** backups meet an agreed freshness target without competing for
the same resources unnecessarily, and representative excluded/included paths
are verified with a dry run and restore.

<a id="ops-003"></a>

### [ ] OPS-003 Run backups and syncs as home programs — P1 · M

**Evidence:** [mkSystemTimer](system/lib/mkSystemTimer.nix) names units only by
job name, so multiple users would collide. The database-client backup exits on
`git diff --quiet`, which misses untracked-only work, and obtains its commit
message from a network service. Shell backup aliases also hardcode framework's
repositories in [aliases.zsh](home/programs/zsh/aliases.zsh), though the
restic module already installs a `restic-<name>` wrapper for each one.

Timers are also the one feature that a host turns on for a user
(`dotfiles.modules.timers.users`). Everything else is a program the user turns
on.

**Decided:** backups and syncs become home programs with user timers, turned
on with `enableFor`. **Verified:** the pinned Home Manager ships
`services.restic` with the options the NixOS module has: `paths`, `exclude`,
`timerConfig`, `pruneOpts`, `checkOpts`, and a wrapper for each repository. It
runs on Linux only, which is all that is needed.

**Plan:**

1. Store the second copy of the password ([OPS-004](#ops-004)) and run the
   restore drill ([OPS-001](#ops-001)) before touching working backups.
2. Add a `backups` program with `bin/new program`. Its settings
   ([CONFIG-006](#config-006)) are the repositories and the paths. It fills
   `services.restic.backups` from them.
3. Add `sync-books` and `backup-dbclient` as programs with user services and
   timers. Fix the dbclient script on the way: `git status --porcelain` sees
   untracked files, the commit message is the host and date, and it pushes
   even when there is nothing new to commit, so a failed push is tried again.
4. Give each service a working directory, a timeout, and a restart limit.
5. Turn all three on in `nelson.nix` with `enableFor [ "framework" ]`.
6. Run the new backup against a test repository for a week, beside the old
   one. Then delete `system/timers/`,
   [mkSystemTimer](system/lib/mkSystemTimer.nix), the `timers` lines in
   `framework.nix`, and the three restic aliases.
7. Note the cost in the program's comment: user timers run only while you are
   logged in. On the laptop that is fine. A server would need lingering.
8. Say in the `sync-books` program that `rclone sync` mirrors deletions and is
   not a versioned backup.

**Verify:**

- `systemctl --user list-timers` on framework shows the three jobs on the
  same schedule as before.
- The new wrapper lists the same snapshots as the old one:
  `restic-mega snapshots`.
- With the network off, the dbclient service fails with a clear log line. The
  next run pushes the pending commit.
- A new untracked file is committed on the next run.
- `grep -rn timers system/` finds nothing.

**Done when:** backups turn on with one `enableFor` line in the user file;
offline runs fail clearly and recover; untracked-only changes and pending
pushes are covered.

<a id="ops-004"></a>

### [ ] OPS-004 Document secrets and first-login provisioning — P1 · M

**Evidence:** timers expect an external Restic password, rclone configuration,
and SSH key. [system/nixos.nix](system/nixos.nix) creates accounts but does not
define a repository-wide first-login or credential provisioning process.

**Decided:** a written checklist, with no sops-nix or agenix. The surveyed
configs split about evenly between the two, and either earns its place once a
secret must reach a second machine. Look again then.

**Plan:**

1. **Do this first, before any code.** The restic password and the rclone
   config exist only on framework. Lose the laptop and nobody can open the
   backups. Store a copy of both in a password manager, and of the SSH key if
   it has no copy.
2. Add a table to the README: each secret's path, owner, mode, which job reads
   it, how to create it, and where the recovery copy lives. No values.
3. Give each timer a clear failure when its secret is missing
   (`ConditionPathExists=` or a first-line check).
4. Add a check that fails when a file that looks like a credential is tracked.
   It prints paths, never contents. `gitleaks` is already installed.

**Verify:**

- On another machine, with only the stored copies, `restic -r … snapshots`
  lists the snapshots.
- On a fresh user account, following the table makes the first backup pass.
- Track a fake key on a branch: the check fails and names the path.

**Done when:** a fresh machine can obtain login access and backup credentials
from documented steps, with no dependency on secrets available only on the
failed machine.

<a id="ops-005"></a>

### [ ] OPS-005 Review temis network access and service exposure — P2 · S

**Evidence:** [temis.nix](system/hosts/temis.nix) enables SSH and Docker while
explicitly disabling the firewall. No account has `openssh.authorizedKeys` in
the repo, and no sshd setting is declared, so password login is on by default.
This review did not inspect its real network exposure.

**Decided:** temis is reached over Tailscale only. That lowers the risk, so
this drops from P1 to P2. The steps below make the config say what the network
already does.

**Plan:**

1. Confirm the answer. `ip -br addr` shows no public address, or the
   provider's firewall blocks every port. List what listens: `ss -tlnp` and
   `docker ps`.
2. Declare the SSH keys: add a key list to each user in `config/users.nix`
   and set `users.users.<name>.openssh.authorizedKeys.keys` from it.
3. Harden sshd: `PasswordAuthentication = false`,
   `KbdInteractiveAuthentication = false`, `PermitRootLogin = "no"`.
4. Turn the firewall on: trust `tailscale0` and open nothing else. Docker
   publishes ports past the firewall, so bind published ports to the
   Tailscale address.
5. Keep a second SSH session open, and use `nixos-rebuild test` first. It
   reverts on reboot.
6. Review `extraGroups` per host. The server does not need `lpadmin` or
   `libvirtd`.

**Verify:**

- From outside the tailnet, `nmap -Pn <address>` shows nothing open. From the
  tailnet, SSH works.
- `ssh -o PreferredAuthentications=password temis` is refused.
- A new SSH session works before the old one is closed.

**Done when:** allowed services are documented and tested from the intended
networks, administrative access is preserved, and unexpected listeners are
identified. Do not assume Tailscale alone defines the host's exposure.

<a id="ops-006"></a>

### [ ] OPS-006 Align rollback and garbage-collection policy — P1 · S

**Evidence:** [bin/autoclean](bin/autoclean) uses seven-day deletion while
[system/nixos.nix](system/nixos.nix) configures monthly collection with 31-day
retention. The README explains build and switch but has no recovery procedure.

**Plan:**

1. Pick one window, such as 14 days, and use it in `bin/autoclean`, `nix.gc`,
   and the boot entry limits.
2. Add `bin/autoclean --dry-run`, which lists the generations it would delete.
3. Write a recovery section in the README: system rollback
   (`nh os rollback` or the boot menu), home rollback, a failed activation,
   and the matching `git checkout`. Say plainly that live links mean an old
   generation alone does not bring back old app config.
4. Note that Determinate Nix runs its own collection on the Mac.

**Verify:**

- `bin/autoclean --dry-run` lists only generations older than the window.
- Follow the walkthrough once on framework: roll back one home generation and
  return.

**Done when:** a recovery walkthrough identifies both the generation and source
revision needed, and cleanup preserves the intended recovery window.

## 4. Improve daily development and reproducibility

<a id="dx-001"></a>

### [ ] DX-001 Remove network cloning from shell activation — P1 · M

**Evidence:** [zsh.nix](home/programs/zsh/zsh.nix) pins plugins but clones Oh My
Zsh from its current Git branch during activation. The clone skips Home
Manager's `run` wrapper, so a dry run clones too, and a first activation with
no network fails. The runtime shell then sources that mutable checkout. Six
plugins are pinned by hand; `zsh-vi-mode` is fetched and never loaded.

Home Manager's `programs.zsh.oh-my-zsh` takes its copy from `pkgs.oh-my-zsh`,
which `flake.lock` pins.

**Plan:**

1. Point `ZSH` at `${pkgs.oh-my-zsh}/share/oh-my-zsh` with a session variable.
   Make [theme.zsh](home/programs/zsh/theme.zsh) read it instead of setting
   `~/.oh-my-zsh`.
2. Point `ZSH_CUSTOM` at a folder Home Manager owns, and link the plugins and
   the theme there. Keep the pins, or use the nixpkgs packages
   (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-fzf-tab`,
   `zsh-powerlevel10k`) so `bin/update` moves them.
3. Delete the `cloneOhMyZsh` activation step and the `zsh-vi-mode` pin.
4. Turn off Oh My Zsh's self-update.
5. Remove the old `~/.oh-my-zsh` by hand on each machine after the switch.

**Verify:**

- `zsh -ic 'echo $ZSH'` prints a store path.
- With the network off, a switch into a fresh home works and the prompt loads.
- Build the same commit twice: the same Oh My Zsh path.

**Done when:** activation needs no shell-framework network fetch after the
closure is built, and rebuilding the same inputs selects the same framework.

<a id="dx-002"></a>

### [ ] DX-002 Measure and simplify shell startup — P2 · M

**Evidence:** **Measured** on the Mac: an interactive shell starts in 0.48 s,
and `compinit` is at the top of `zprof`.

- **`compinit` runs twice.** Home Manager writes a bare
  `autoload -U compinit && compinit` at line 8 of `~/.zshrc`, and Oh My Zsh
  runs it again. The `fpath` strip in the Homebrew module is a workaround for
  that bare call; its comment says so.
- **`eval $(gitleaks completion zsh)` does nothing.** After it runs, no
  `_gitleaks` function exists: the unquoted output loses its line breaks.
  The completion that works comes from the package's own `_gitleaks` file.
  The line still starts gitleaks in every zsh.
- **The `*.init` loop finds nothing.** No such file is tracked. It walks the
  whole checkout, `.git` included, on every start.
- [zshrc](home/programs/zsh/zshrc) loads its modules with `ls | sort` and
  unquoted loops, which break when the checkout path has a space.
- [plugins.zsh](home/programs/zsh/plugins.zsh) turns on fzf, direnv, mise, and
  zoxide whether or not those programs are enabled. fzf is set up twice.

**Plan:**

1. Record the baseline: `hyperfine 'zsh -ic exit'`, and `zprof` for the top
   ten.
2. Delete the gitleaks line and the `*.init` loop.
3. Set `programs.zsh.enableCompletion = false`, so only Oh My Zsh runs
   `compinit`. Then try removing the `fpath` strip on the Mac.
4. Load the zsh modules with a quoted glob: `for f in "$DOTFILES"/home/programs/zsh/*.zsh`.
5. Build the plugin list from the enabled programs, or guard each plugin with
   `command -v`.
6. Set a target from the new numbers and write it here.

**Verify:**

- `zprof` shows one `compinit` call.
- `hyperfine` before and after.
- `nix <TAB>` and `git <TAB>` still complete. If Nix completion is gone, add
  `nix-zsh-completions` to the zsh program.
- A checkout at a path with a space starts a clean shell.
- A home with only zsh enabled starts with no "command not found".

**Done when:** a minimal home opens a usable shell without missing-command
errors; startup from a checkout containing spaces works; before/after timings
show whether the change helped. Set a latency target after taking the baseline.

<a id="dx-003"></a>

### [ ] DX-003 Make runtime ownership explicit — P2 · M

**Evidence:** Python and Ruby come from Nix, Node and Go modules supply mise
defaults, Rust uses rustup, and Neovim combines Nix language servers with Mason.
These are reasonable choices but their boundaries are not documented together.

**Plan:**

1. Add a table to the README: for each language, who owns the runtime, who
   owns project versions, and who owns the language server.
2. Document the `PATH` order and how a project overrides it (mise or a
   project flake with direnv).
3. Add one small project example for Elixir, the language used most.

**Verify:**

- `which -a python ruby node go elixir` in a new shell matches the table.
- A project with a `mise.toml` picks its own version without touching the
  global one.

**Done when:** it is clear why a given executable/version is selected, and new
projects do not depend accidentally on tools installed by another editor or
runtime manager.

<a id="dx-004"></a>

### [ ] DX-004 Reproduce editor dependencies and first launch — P2 · M

**Evidence:** [Neovim plugins](home/programs/nvim/plugins.lua) bootstrap
`lazy.nvim` from a moving `stable` branch; no Neovim lockfile is tracked here.
Several LSP commands reference Mason paths, while the declared install list
does not cover every enabled server. [init.lua](home/programs/nvim/init.lua)
also depends on `DOTFILES` being set. VS Code's extension scripts use a path
relative to the caller's working directory.

**Plan:**

1. Track `lazy-lock.json` in the repo and link it, so plugin versions move
   only when you say.
2. List every enabled language server. Each must come from Nix or from the
   Mason install list.
3. Give `init.lua` a fallback when `DOTFILES` is unset.
4. Make the VS Code scripts find `extensions.txt` from their own location.

**Verify:**

- `HOME=$(mktemp -d) nvim --headless '+Lazy! restore' +qa` exits 0.
- `env -u DOTFILES nvim --headless +qa` exits 0.
- `:checkhealth` reports no missing server.
- The VS Code script works when run from another folder.

**Done when:** a clean temporary home can start the editor, find its config,
and open representative projects; missing dependencies report actionable
errors. Test first launch separately from a mature local installation.

<a id="dx-005"></a>

### [ ] DX-005 Formalize live, generated, and app-owned files — P2 · M

**Evidence:** [mkSymlink](home/lib/mkHomeModule.nix) validates repository source
existence, but live targets still depend on the checkout remaining in place.
Claude has a custom direct-link activation with unquoted paths, and
`ln -sfn` replaces a real `settings.json` without a backup. Herdr copies mods
and allows apps to write through some configuration links.

**Plan:**

1. Add a table to the README: for each app, which files are live links,
   generated, copied, or owned by the app.
2. Assert that `dotfiles.directory` is an absolute path outside the Nix store.
3. Check before activation that the checkout exists and is this repo. Fail
   with the fix: "clone to … or set dotfiles.directory".
4. Quote every path in the custom activation steps. Back up a real file
   before linking over it.
5. Write down how to move the checkout: set the option, switch, done.

**Verify:**

- Activation tests in a temporary home cover: an existing real file, a broken
  link, a second run, and a path with a space.
- With the checkout renamed, `bin/build home` passes and the switch stops at
  the check with the hint.

**Done when:** users can tell which edits require rebuilding or reloading, which
survive rollback, and which are overwritten. Activation tests cover existing
files, broken links, repeated runs, and paths with spaces without touching the
real home.

<a id="dx-006"></a>

### [ ] DX-006 Add a read-only diagnostic command and finish onboarding — P2 · M

**Evidence:** useful diagnostics are spread across the README and helpers. The
README and a comment in `flake.nix` promise automatic direnv loading.
**Verified:** commit `f6bf77f6` added `.envrc`, and the next commit,
`c15fee8c` ("[herdr-app]: add mods"), deleted it. [home/scripts.nix](home/scripts.nix)
also assumes GNU `stat`/`date` and particular generation directories.

**Plan:**

1. Restore `.envrc` with `use flake`.
2. Add `bin/doctor`. It only reads. It reports this host's outputs, the Nix
   features, the checkout path, links whose target is missing, missing
   secrets by path, backup age, and the next command to run.
3. Make the generation-diff helpers handle no generations, a cancelled pick,
   and macOS ([CONFIG-003](#config-003) moves them).
4. Walk the README install steps on a fresh clone for each kind of host.

**Verify:**

- `direnv allow` once, then `cd` into the repo puts `xonsh` on `PATH`.
- `bin/doctor` runs before any switch and prints no secret.
- Remove a linked file's target: `bin/doctor` names it.

**Done when:** a fresh clone has a tested setup/build path for NixOS, standalone
Home Manager, and the managed Mac; diagnosis works without a successful switch.

<a id="dx-007"></a>

### [ ] DX-007 Keep the docs and the repo in step — P2 · S

**Evidence:** the docs drift, and nothing notices:

- `.envrc` was deleted one commit after it was added ([DX-006](#dx-006)). The
  README still describes it.
- AGENTS.md says "Agents run on the Linux machine. You can't run commands on
  the Mac." This review ran on the Mac.
- The hosts table is written by hand in the README and in AGENTS.md, apart
  from `config/hosts.nix`.
- The scripts table is written by hand, apart from `bin/`.

**Plan:**

1. Rewrite the AGENTS.md line: check `hostname` first, then ask for commands
   on the other OS.
2. Add a docs test to `tests/`: every file the README and AGENTS.md link to
   exists, every `bin/*` script is in the scripts table, and the hosts tables
   match `config/hosts.nix`.
3. Run it with the other tests ([CI-001](#ci-001)).

**Verify:**

- Delete `.envrc` on a branch: the test fails and names it.
- Add a host with `bin/setup`: the test fails until both tables have it.

**Done when:** a doc that names a missing file, script, or host fails a check.

## 5. Improve CI and maintenance efficiency

<a id="ci-001"></a>

### [ ] CI-001 Add fast checks for the files that actually change — P2 · M

**Evidence:** [flake.nix](flake.nix) lints Nix, but the repository also holds
178 Nix files, 33 files with no extension (scripts and configs), 19 JSON, 10
YAML, 6 zsh, 6 Lua, 3 TOML, and 3 shell files, plus the Herdr mods.

- **Verified:** the 16 scaffolding tests pass, and neither CI nor a flake
  check runs them.
- **Verified:** `shellcheck` reports nothing on the six shell scripts, and
  `zsh -n` passes on the zsh files. Adding both costs nothing today.
- The Herdr
  [profile-picture test](home/programs/herdr-app/mods/profile-pictures/remote.test.mjs)
  is never run. Node is not in the dev shell.

**Plan:**

1. Use one formatter config for everything, with no new input:
   `nixfmt-tree.override { settings = …; runtimeInputs = [ shfmt stylua taplo ruff ]; }`.
   Both it and `treefmt.withConfig` are in the pinned nixpkgs. Use it as the
   flake's `formatter` and in the lint check (`treefmt --ci`). Leave out
   `flake.lock` and the mods that come from upstream.
2. Add to the lint check: `shellcheck`, `zsh -n`, `actionlint` for the
   workflow, and `--help` on every helper, which catches xonsh syntax errors.
3. Add `bin/test`. It runs the Python tests and the JS test
   (`node --test`). Add Node to the dev shell.
4. Run `bin/test` in the first CI job ([CI-006](#ci-006)).
5. Add an opt-in hook: a tracked `.githooks/pre-push` that runs `bin/lint` and
   `bin/check --eval`, about 20 seconds. Turn it on with
   `git config core.hooksPath .githooks`. No hook framework is needed.

**Verify:**

- On a branch, add a shell syntax error, a badly formatted Lua file, and a
  broken workflow key. Each fails the first job in under two minutes.
- `nix fmt` formats Lua and shell files, and leaves the upstream mods alone.
- With the hook on, a push with a lint error is refused.

**Done when:** representative script/config mistakes fail before expensive
builds; dependencies are pinned through the dev shell/check derivations; a
documentation-only edit has an appropriately cheap validation path.

<a id="ci-002"></a>

### [ ] CI-002 Measure build costs and make cache retention resilient — P1 · M

**Evidence:** **Measured** from the Actions API:

| Run | Linux `nix flake check` | Free disk | Save cache |
| --- | --- | --- | --- |
| Warm (`ff5f8f17`) | 1387 s | 98 s | 203 s |
| Cold, after an input bump | 3716 s | 97 s | 221 s |
| Failed run (`27969c49`) | 652 s | 270 s | — |

- Almost all of the warm time goes to downloading the closure, about 50 GiB
  by the workflow's own comment, to put three home configs together.
- The cold time is two builds from source: vicinae (about an hour) and
  herdr-app (about 35 minutes).
- The saved cache keeps only those two. **Verified:** the Home Manager man
  page is not in `cache.nixos.org`, so every run builds it again.
- The cache is saved only after `nix flake check` passes, so a failed run
  loses its builds.
- The laptop gets none of this. After an input bump, framework compiles
  vicinae itself.

Facts checked on 2026-11-12:

| Option | What it gives | Cost |
| --- | --- | --- |
| Cachix | A cache your machines can use too | 5 GB free for open source |
| Hestia (`Mic92/hestia`) | A cache inside the Actions cache; no account or secret | Free; CI only; young |
| garnix | Builds the flake's outputs itself and serves a cache | 1,500 minutes a month free; Mac minutes not confirmed |
| GitHub Actions cache | What the workflow uses now | 10 GB, entries dropped after 7 unused days |

**Decided:** Cachix, on CI and on all four machines, the work Mac included.

**Plan:**

1. Print `df -h / /nix` and each step's time for a week. Add the table here.
2. Create the Cachix cache and put its token in the repo's secrets. In CI,
   build the packages that come from source with
   `nix-fast-build --skip-cached --cachix-cache <name>`. It builds only what
   the cache lacks and pushes the result. Start with the two paths that "Keep
   the slow builds" names today; move to the `packages` output when
   [CONFIG-009](#config-009) lands. Then delete the cache-nix-action step and
   "Keep the slow builds".
3. Add the cache and its public key to each machine: `nix.settings` on NixOS,
   the Determinate config on the Mac, and Home Manager's `nix.settings` on
   thinkpad. Check with `nix config show substituters`.
4. If `df` shows room, drop the free-disk step. One outside measurement found
   about 86 GiB free on public runners this month; check before you trust it.
5. Turn off the Home Manager man page (`manual.manpages.enable = false`) if
   you never read `man home-configuration.nix`.
6. Take vicinae from nixpkgs ([CONFIG-012](#config-012)). That leaves
   herdr-app, about 35 minutes, as the one long build for the cache to hold.

**Verify:**

- Run the same commit twice: the second run builds nothing from source.
- After CI builds an input bump, `bin/build home` on framework downloads
  vicinae and does not compile it.
- The run-time table, before and after.

**Done when:** repeat runs demonstrably reuse the expensive outputs, cache
targets survive host renames or disabled programs, and failures preserve useful
diagnostics. Do not optimize by silently dropping configuration coverage.

<a id="ci-003"></a>

### [ ] CI-003 Cover the gap between evaluation and activation — P2 · L

**Evidence:** current checks build Home Manager activation packages but only
evaluate system toplevels. No job has ever built a NixOS system. Neither step
exercises live links, timer execution, desktop behavior, or Workbrew
activation.

**Plan:**

1. In the weekly run ([CI-006](#ci-006)), build both NixOS systems:
   `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`.
2. Add one small VM test with `pkgs.testers.runNixOSTest` for the timers: the
   units exist, start, and run as the right user. GitHub's Linux runners have
   KVM.
3. Test the custom activation steps (Herdr mods, the Claude link) in a
   temporary home ([DX-005](#dx-005)).
4. Keep a short Mac checklist in the README: the shell starts, apps are on
   `PATH`, `brew` works, rollback works.

**Verify:**

- The weekly run lists, for each config: evaluated, built, VM-tested, or
  checked by hand.
- Break a timer's user on a branch: the VM test fails.

**Done when:** reports distinguish evaluated, built, activated, and manually
verified behavior. Keep expensive coverage separate from fast feedback.

<a id="ci-004"></a>

### [ ] CI-004 Track external patches, assets, and workflow dependencies — P2 · M

**Evidence:** [config/overlays.nix](config/overlays.nix) carries temporary Herdr
and GNOME fixes, while Herdr mods include substantial copied upstream code and
icons. **Measured:** 1,430 of the 1,724 tracked files are mods, and 1,190 of
those are one icon set (5 MB). CI uses version tags and a moving `main`
reference (`jlumbroso/free-disk-space@main`) for external actions.

**Plan:**

1. Pin every action to a commit and let Dependabot propose updates. Add
   `zizmor` to the lint check to keep it that way.
2. Add a table in `home/programs/herdr-app/`: each mod's source, revision,
   license, and whether it is yours, upstream, or upstream with your fixes.
3. **Decided:** track only the mods written here, and fetch the rest at a
   pinned revision. The activation step then copies those from the Nix store,
   not from the checkout.
   - Upstream mods you don't change, and the icon set (it carries the
     material-icon-theme license): pin upstream.
   - Upstream mods you keep fixing: pin your fork. **Measured:** 12 of the
     last 34 commits edit the `t4-*`, `call`, `chat`, and `pasture` mods. As
     patch files, every fix would mean a new patch. In a fork they are normal
     commits, and they can go upstream.
   - Know the cost. A fix to a pinned mod needs a push and a pin bump before
     `bin/rebuild home` picks it up. Today an edit in the checkout is enough.
4. Give each override its own removal check ([CONFIG-009](#config-009)).
5. On every input bump, read the warnings and remove what they name.

**Verify:**

- `zizmor .github/workflows` reports no unpinned action.
- `git ls-files | wc -l` drops by more than 1,200, and the icons and the
  fetched mods still show in Herdr after a switch.
- Every row in the mods table names a license.

**Done when:** an input upgrade includes a short patch/vendor review, stale
workarounds are removed when verified unnecessary, and imported assets retain
their provenance and licenses.

<a id="ci-005"></a>

### [ ] CI-005 Separate package reconciliation from surprise upgrades — P2 · M

**Evidence:** [Homebrew activation](system/modules/darwin/homebrew/homebrew.nix)
sets `autoUpdate`, `upgrade`, and `cleanup = "uninstall"`. Thus the same Nix
revision can trigger different external package changes on different days.
The module also documents a possible Workbrew/sudo conflict.

**Decided:** the owner reports that the Homebrew step works on the work Mac.

**Plan:**

1. Set `autoUpdate` and `upgrade` to `false`. A switch then only installs and
   removes. Upgrades become their own step, `brew upgrade`.
2. Before a switch, print what cleanup would remove
   (`brew bundle cleanup` without `--force`).
3. Replace the warning in the module's comment with the fact: `brew bundle`
   runs under Workbrew on this Mac.
4. Write down who owns each Mac app: Nix, Workbrew, or the app itself (Herdr
   updates itself).

**Verify:**

- Two switches a day apart at the same commit change nothing.
- A cask removed from the list shows up in the preview before it is removed.

**Done when:** a routine configuration switch has a predictable scope and the
docs distinguish declarative selection from version reproducibility.

<a id="ci-006"></a>

### [ ] CI-006 Build only when a configuration changed — P1 · M

**Evidence:** **Measured:** of the 33 commits since the last input bump, one
changed any config's derivation (`c15fee8c`, and it changed two of seven).
The rest touched scripts, docs, live-linked config files, and Herdr mods. None
of those enter a derivation. Each push still ran the 28-minute Linux job.

Two more problems:

- `on: [push, pull_request]` runs every commit on a PR branch twice. The run
  list shows it on `share-overlays`, `host-timers`, and `wallpaper-home-dir`.
- No job evaluates all seven configs quickly. The first sign of an option
  error comes from inside the slow jobs, after the disk cleanup.

A derivation's hash covers everything that goes into the build. If a config's
derivation has built before, building it again proves nothing new. So skipping
it loses no confidence.

**Plan:**

1. Triggers: `push` on `wip`, `main`, and `update/**`, a weekly `schedule`,
   and `workflow_dispatch`. **Decided:** work goes to `wip` and is merged to
   `main` by hand. So there is no `pull_request` trigger, no double run, and
   no required check. The merge to `main` carries the same derivations, so
   its build is skipped.
2. Job `quick`, on Linux with no disk cleanup and no store cache: lint,
   `bin/test`, `nix flake check --no-build --all-systems`, and the derivation
   list from [CLI-006](#cli-006) as a job output. Expect two to four minutes.
3. Job `build`, once per system. Its key is the hash of that system's part of
   the list. Look up `green-<system>-<hash>` with `actions/cache/restore` and
   `lookup-only`. On a hit, skip the build and say so in the job summary. On
   a miss, build as today, then save an empty marker under that key.
4. The weekly run ignores the markers and builds everything. It catches a
   source that vanished or a cache that went stale.
5. Later, keep one marker per check. A Mac-only change then builds nothing on
   Linux.

**Verify:**

- Push a README-only commit: `build` ends in under a minute and says "already
  built". The whole run takes under five minutes.
- Push a commit that adds a package: `build` runs. Run it again: skipped.
- Misspell an option: `quick` fails in under four minutes and `build` never
  starts.
- After a month, compare the median run time with the baseline.

**Done when:** a push that changes no config finishes in minutes, and a push
that changes one still gets a full build.

**Notes:**

- A marker means "this exact set built once". Markers are dropped after seven
  unused days. A miss costs one build, never a wrong pass.
- `nix-fast-build --skip-cached` with a binary cache can do the same for each
  check, by asking the cache whether the output exists. But that means
  pushing every home generation to Cachix, and the free 5 GB would fill up.
  So keep the two jobs apart: markers answer "has this config built before?",
  and Cachix holds the packages built from source ([CI-002](#ci-002)).
- This does not shorten the build when a Linux home does change. That time is
  the download. [CONFIG-003](#config-003) and [CI-002](#ci-002) work on it.

<a id="ci-007"></a>

### [ ] CI-007 Open input-update PRs on a schedule — P2 · S

**Evidence:** inputs move only when someone runs `bin/update --save`. A break
upstream then shows up on the laptop, in the middle of other work, with an
hour of compiling in front of it.

**Plan:**

1. Add a weekly workflow: run `bin/update --save` on the branch
   `update/inputs` and open a PR. It reuses the script, so the
   `chore: upgrade …` commit keeps its format.
2. Make sure CI starts. A push or a PR made with the default `GITHUB_TOKEN`
   does not trigger workflows. Start the CI workflow on the branch with
   `gh workflow run`, or push with a fine-grained token.
3. Let CI build it and fill the cache ([CI-002](#ci-002)).
4. **Decided:** merge by hand, when it is green and you have time to rebuild.

**Verify:**

- A PR appears on schedule, with the body `bin/update` writes.
- After the merge, `bin/build` on framework downloads the new builds.
- A failed build leaves the PR open and red.

**Done when:** inputs are at most a week old, and a breaking update is found
by CI, not on the laptop.

**Needs:** [CLI-002](#cli-002) (no terminal) and [CI-002](#ci-002).

## 6. Optional extensions after the foundations

<a id="platform-001"></a>

### [ ] PLATFORM-001 Generate an inventory from evaluated configuration — P3 · M

Expose a human-readable and JSON view of hosts, roles, users, enabled programs,
and available outputs. Use it for diagnostics and script target selection
instead of separately parsing Nix source. Explain inclusion through explicit
role/profile metadata where practical; do not build a general provenance engine.

The two commands under [How to check a change](#how-to-check-a-change) already
give the lists. This task makes them one command.

**Plan:**

1. Add `bin/check --inventory [<user>@<host>]`: programs on, programs off,
   and package count.
2. Use it in `bin/doctor` ([DX-006](#dx-006)) and for the hosts tables
   ([DX-007](#dx-007)).

**Verify:** its output for all four configs matches the baseline table above.

**Done when:** the inventory agrees with evaluated outputs and removes at least
one duplicated source of truth.

<a id="platform-002"></a>

### [ ] PLATFORM-002 Make reinstalling and remote maintenance repeatable — P3 · L

Document disk layout, boot mode, encryption recovery, first login, and restoring
data for each NixOS machine. Decide whether declarative disk provisioning is
worth introducing. Add remote build/deployment support only if temis maintenance
needs it, with explicit target selection, preview, connectivity checks, and a
rollback route. Keep activation separately authorized.

**Plan:**

1. Write the reinstall steps for framework (LUKS, EFI) and temis (BIOS, GRUB).
2. Try disko at the next reinstall, not before. Five of the surveyed configs
   use it.
3. For temis, a script around `nixos-rebuild --target-host` is enough for two
   or three machines. Add it only when SSH-and-rebuild gets tiresome.

**Verify:** install a throwaway VM from the written steps alone.

**Done when:** a disposable VM or spare machine can be installed from the
instructions, and remote operations cannot accidentally select the local host.

<a id="platform-003"></a>

### [ ] PLATFORM-003 Audit desktop services and inactive configurations — P3 · M

Measure idle memory, startup services, GNOME extension behavior, and app launch
times before tuning. Review disabled editors, window managers, modules, and
large copied assets for continued usefulness. Keep intentional alternatives;
archive abandoned experiments with enough history to recover them.

**Plan:**

1. **Decided:** keep the 13 programs that are off for every user as
   alternatives: hyprland, wezterm, zellij, espanso, digikam, pinta, shotcut,
   vlc, wine, zeal, mysql, podman, opencode. They cost nothing while off.
2. Keep them working. Turn each one on in a fixture config in the tests
   ([CONFIG-002](#config-002)), so an alternative can't rot unseen.
3. Measure idle memory and startup services on framework before tuning
   anything.
4. Write the desktop checklist once, in the README.

**Verify:** the fixture with all 13 turned on evaluates on Linux.

**Done when:** removals have a clear maintenance or measured resource benefit,
and desktop changes have a short regression checklist covering shortcuts,
theme changes, display behavior, audio, suspend, and notifications.

<a id="platform-004"></a>

### [ ] PLATFORM-004 Set the generic-Linux target on home-only hosts — P3 · S

**Evidence:** thinkpad runs Home Manager on another distro. Nothing in the
repo sets `targets.genericLinux.enable`. Home Manager offers it for exactly
this case: it helps Nix-installed programs find fonts, icons, desktop entries,
and the host's graphics drivers.

**Decided:** thinkpad is rarely used and gets no desktop apps, so this waits.
It keeps building in CI.

**Plan:**

1. In [home/default.nix](home/default.nix), turn it on when the host is Linux
   and has no `platform`. The home builder already knows both facts.
2. Add a fixture for it to the tests ([CONFIG-002](#config-002)).

**Verify:**

- `bin/check --same` shows only `nelson@thinkpad` changed.
- On thinkpad, `bin/build home` passes. After a switch, `XDG_DATA_DIRS`
  includes the Nix profile and a Nix-installed app shows in the launcher.

**Done when:** a new home-only Linux host gets the target without a line in a
user file.

<a id="platform-005"></a>

### [ ] PLATFORM-005 Add the Framework's hardware profile — P3 · S

**Evidence:** [framework/hardware.nix](system/hosts/framework/hardware.nix) is
the generated file and nothing more. The `nixos-hardware` project keeps
profiles for Framework laptops (power, firmware, and suspend fixes). Firmware
updates (`fwupd`) are not enabled.

**Decided:** the laptop is a Framework 16. **Verified:** `nixos-hardware` has
`framework-16-7040-amd` and `framework-16-amd-ai-300-series`. `lscpu` on the
laptop says which board it is.

**Plan:**

1. Add the `nixos-hardware` input and import the matching profile for
   framework only, through `config/modules.nix` ([CONFIG-007](#config-007)).
2. Turn on `services.fwupd`.
3. Read the package diff from `bin/build os` before switching.

**Verify:** after the switch, suspend, the fingerprint reader, audio, and
external displays work ([PLATFORM-003](#platform-003) checklist), and
`fwupdmgr get-devices` lists the laptop.

**Done when:** the profile is in, or the diff shows it adds nothing and this
task is closed.

## Ideas from other configs

About 15 configs were read at their current default branch, among them
Misterio77, ryan4yin, mitchellh, hlissner, Mic92, khanelinix, wimpysworld,
EmergentMind, NotAShelf, and numtide's blueprint. The closest match to this
repo is `wimpysworld/nix-config`: a data registry builds every NixOS, Mac, and
`user@host` output.

| Idea | Seen in | Verdict |
| --- | --- | --- |
| Check host data with typed options | wimpysworld, EmergentMind, srid | **Adopt:** [CONFIG-001](#config-001) |
| One formatter config for `nix fmt`, the check, and the hook | Mic92, khanelinix, NotAShelf | **Adopt:** [CI-001](#ci-001) |
| Packages as flake outputs, bumped with `nix-update` | Misterio77, khanelinix, Mic92 | **Adopt:** [CONFIG-009](#config-009) |
| Tests for the pure helpers | ryan4yin, blueprint, khanelinix | **Adopt:** [CONFIG-002](#config-002) |
| `.envrc` with `use flake` | all nine that were checked | **Adopt:** quick win |
| Generic-Linux target from the host's kind | wimpysworld | **Adopt:** [PLATFORM-004](#platform-004) |
| Home Manager manual turned off | Mic92 | **Adopt:** [CI-002](#ci-002) |
| A check that compares generated text with the docs | wimpysworld | **Adopt:** [DX-007](#dx-007) |
| "All of" and "any of" tag helpers | wimpysworld | **Adapt:** `&&` already works; document it ([CONFIG-004](#config-004)) |
| The checkout path as a typed option that can't be a store path | hlissner | **Adapt:** [DX-005](#dx-005) |
| A CI job list made from the flake's outputs | lovesegfault, Hestia | **Adapt:** [CI-006](#ci-006) |
| A leading `_` hides a folder from discovery | hlissner, import-tree | **Adapt:** [CONFIG-002](#config-002) |
| flake-parts, snowfall, blueprint | about half of them | **Skip:** `lib/` is 260 lines and does the job. khanelinix left snowfall. |
| Home Manager as a NixOS module | Misterio77 | **Skip:** it ends standalone homes on thinkpad. |
| Import lists and profiles of modules | NotAShelf, hlissner, fufexan | **Skip:** enable flags and roles cover it, and the owner wants two full user lists ([CONFIG-004](#config-004)). |
| One shared nixpkgs instance | NotAShelf, blueprint | **Measure first:** [CONFIG-011](#config-011) |
| Impermanence, colmena, deploy-rs | Misterio77, ryan4yin | **Skip:** too much for three machines. |
| A hook framework | lovesegfault, ryan4yin | **Skip:** a five-line hook is enough. |
| sops-nix or agenix | split about evenly | **Skip for now:** a checklist ([OPS-004](#ops-004)). |

One more idea was weighed and set aside. Of the 109 program modules, 82 are
12 lines or fewer and mostly just install a package. A table of one-line
programs would save about 700 lines. It would also create a second way to add
a program, and `bin/new` makes the folder for free. Keep the folders. The
owner went further that way on purpose: every package in `home/packages.nix`
gets its own folder too ([CONFIG-003](#config-003)).

## Suggested delivery order

Slow CI is the top pain, so it comes right after the quick wins.

1. **Before anything else:** store a second copy of the backup password
   ([OPS-004](#ops-004), step 1). It needs no code.
2. **Quick wins.** The table near the top. An afternoon.
3. **Fast CI:** [CI-006](#ci-006), [CONFIG-012](#config-012),
   [CI-002](#ci-002), [CI-001](#ci-001), then [CLI-002](#cli-002) and
   [CI-007](#ci-007). After the first three, a push that changes no config
   takes minutes, and no build takes an hour. [CI-006](#ci-006) can carry the
   derivation list inline until [CLI-006](#cli-006) exists.
4. **Trust the tooling:** [CLI-006](#cli-006), [CLI-001](#cli-001),
   [CLI-004](#cli-004), [CONFIG-001](#config-001), [CONFIG-002](#config-002).
   `bin/check --same` comes first because the later refactors lean on it.
5. **Sharpen the model:** [CONFIG-006](#config-006), [CONFIG-010](#config-010),
   [CONFIG-008](#config-008), [CONFIG-003](#config-003),
   [CONFIG-004](#config-004), [CONFIG-009](#config-009). Each step should show
   "same" from `bin/check --same`, or an inventory diff you meant.
6. **Prove recovery:** [OPS-004](#ops-004), [OPS-001](#ops-001),
   [OPS-003](#ops-003), [OPS-006](#ops-006), [DX-001](#dx-001), then
   [OPS-005](#ops-005). Run the restore drill before you move the backups or
   change their retention.
7. **Improve daily use:** [CLI-003](#cli-003), [DX-002](#dx-002),
   [DX-003](#dx-003), [DX-004](#dx-004), [DX-005](#dx-005), [DX-006](#dx-006),
   [DX-007](#dx-007).
8. **Finish CI:** [CI-003](#ci-003), [CI-004](#ci-004), [CI-005](#ci-005),
   [OPS-002](#ops-002).
9. **Later, or when a need shows up:** [CONFIG-005](#config-005),
   [CONFIG-007](#config-007), [CONFIG-011](#config-011),
   [PLATFORM-001](#platform-001), [PLATFORM-002](#platform-002),
   [PLATFORM-003](#platform-003), [PLATFORM-004](#platform-004),
   [PLATFORM-005](#platform-005).

Implement each item as a reviewable change with its relevant validation. Follow
the repository's Nix lint/evaluation/build rules for code changes, update the
README when behavior changes, and preserve approval requirements for switching,
cleanup, updates, commits, and pushes. This roadmap itself authorizes none of
those operations.
