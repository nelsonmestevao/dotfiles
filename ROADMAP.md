# Dotfiles roadmap

This roadmap covers developer experience, simplification, efficiency,
reliability, and missing operational pieces. It is based on a source review of
the repository on 2026-11-12. Unchecked items describe proposed work; completed
items record their implementation and validation. Runtime behavior, build times,
backup health, and the Mac were not tested during the original review.

The current structure is worth keeping: host and user data in `config/`, small
program modules, role-based selection, platform assertions, scaffolding tools,
and Linux/macOS CI. Improve the gaps around those foundations before replacing
the architecture.

## Priorities and scope

| Priority | Meaning | Main outcome |
| --- | --- | --- |
| P1 | Address first | Trust command results, preserve work, and recover data |
| P2 | Next | Make everyday changes faster and reduce duplication |
| P3 | Later or when needed | Extend coverage after measuring the benefit |

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

## 1. Make helper commands dependable

<a id="cli-001"></a>

### [ ] CLI-001 Propagate command failures explicitly — P1 · M

**Evidence:** [bin/check](bin/check), [bin/rebuild](bin/rebuild),
[bin/setup](bin/setup), and [bin/update](bin/update) invoke subprocesses without
consistently checking their status. [bin/build](bin/build) already checks
`returncode` and exits unsuccessfully when a build fails.

Give every helper an explicit failure policy. A failed evaluation must produce
a nonzero exit status; a failed system switch must not silently continue into a
home switch; failed formatting, staging, or committing must not print success.
Test behavior under the pinned Xonsh version instead of depending on ambient
shell settings. Preserve existing `NIX_CONFIG` settings when adding flake flags;
several helpers currently replace the variable entirely.

**Done when:** stub commands returning failure exercise each branch, the helper
returns failure, and no dependent mutation runs. Keep the deliberate behavior
in `bin/build` that attempts both builds and reports aggregate failure.

<a id="cli-002"></a>

### [ ] CLI-002 Make updates selective and commits isolated — P1 · M

**Evidence:** [bin/update](bin/update) always updates all inputs, parses Nix's
human-readable output, then runs an unrestricted `git commit` after staging
`flake.lock`. Any unrelated changes already staged can enter that commit.

Add named-input updates. Compare the old and new lockfile JSON to produce the
summary, including additions, removals, and changed `follows` relationships.
Make `--save` refuse unrelated staged changes or otherwise isolate the lockfile
without disturbing the existing index. Detect a pre-existing lockfile edit and
make its treatment explicit. Add an optional validation step before saving.
Use plain output when there is no terminal instead of relying on `tput` and a
spinner.

**Done when:** fixtures cover no-op updates, changed inputs, update failures,
nonterminal use, and a dirty index; unrelated files never enter the upgrade
commit. Existing approval rules for updates and commits remain in force.

<a id="cli-003"></a>

### [ ] CLI-003 Resolve targets from host data — P2 · M

**Evidence:** [bin/build](bin/build) and [bin/rebuild](bin/rebuild) choose the OS
command from `sys.platform` and default to both OS and home. The README already
documents that the default rebuild fails on a Home Manager-only host.

Resolve hostname, username, and host platform once from the repository's data.
Default to the outputs that actually exist. Add explicit host/user selection
for building another configuration, with clear errors for unknown pairs. Reject
unsupported `--boot` combinations instead of ignoring them. Print the exact
target before a switch. Only extract shared script code where it removes real
duplication.

**Done when:** framework, temis, thinkpad, and the Mac select the expected
outputs in command-routing tests. An explicit OS request on thinkpad fails
before invoking a system builder.

<a id="cli-004"></a>

### [ ] CLI-004 Separate native builds from evaluation of all systems — P1 · S

**Evidence:** [bin/check](bin/check) always passes `--all-systems`, including
when building. [CI](.github/workflows/ci.yml) instead builds native checks on
separate Linux and Mac runners.

Keep evaluation of every system as the fast portability check. Make the normal
local build check native, and expose building foreign systems as an explicit
mode requiring an appropriate builder. Explain that evaluating the Darwin
configuration on Linux does not test activation on macOS.

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

## 2. Validate the model and simplify configuration

<a id="config-001"></a>

### [ ] CONFIG-001 Validate every host and user entry centrally — P1 · M

**Evidence:** [lib/default.nix](lib/default.nix) checks state-version presence
and role/name collisions. Its platform guard validates the argument to
`systemConfigsFor`, but an unknown `hosts.<name>.platform` can be filtered out
of both system outputs while still producing a home output.

Validate each entry before assembling outputs: allowed platform, matching OS,
known users, nonempty and duplicate-free user lists, field types, required
files, and required state versions. Consider rejecting unknown fields to catch
misspellings. Prevent `extraSpecialArgs` from accidentally replacing reserved
arguments such as `host`, `username`, or `enableFor` in
[mkHomeConfig](lib/mkHomeConfig.nix).

**Done when:** invalid fixtures fail with the field and host/user name, even
when an output filter would otherwise hide them. Existing state versions stay
unchanged.

<a id="config-002"></a>

### [ ] CONFIG-002 Add focused regression tests for the shared helpers — P1 · M

**Evidence:** the flake evaluates real configurations, but does not declare
dedicated tests for [role selection](home/lib/enableFor.nix),
[module discovery](lib/importModules.nix), or
[module wrappers](home/lib/mkHomeModule.nix).

Test unknown selectors, role collisions, disabled modules, wrong-platform
activation, missing symlink sources, and malformed module directories. Include
negative fixtures: current hosts only test combinations that happen to exist.
Test script command routing and scaffolding in temporary repositories.

**Done when:** the checks catch the known failure cases without building a
desktop closure or touching the real home. Avoid snapshotting entire generated
configurations or testing trivial package declarations.

<a id="config-003"></a>

### [ ] CONFIG-003 Reduce the server and base-home package sets — P2 · M

**Evidence:** [nelson.nix](home/users/nelson.nix) enables Flutter, Haskell, media
tools, and many language modules everywhere. [home/packages.nix](home/packages.nix)
bundles build tools, GUI-related packages, cloud tools, and utilities behind
one flag, also enabled for temis and thinkpad.

Inventory what each host actually needs. Split the catch-all list into a small
portable base and a few meaningful capabilities, selected in user files through
roles. Keep project-specific toolchains in project environments where useful.
Retain per-program modules for programs with configuration; plain package lists
do not all need their own wrapper.

**Done when:** record closure size and package count before and after; temis has
an intentional server toolset; the portable base evaluates on Linux and Darwin.
Do not remove tools solely because two packages overlap.

<a id="config-004"></a>

### [ ] CONFIG-004 Share user defaults without hiding choices — P2 · M

**Evidence:** [the two user files](home/users) repeat much of the shell and CLI
selection. Some choices use specific host names despite describing a platform
capability, such as Colima and cmux.

Extract a small common CLI selection only where the users agree. Keep identity,
desktop preferences, and host exceptions visible in user files. Prefer roles
for recurring capabilities and keep hostname exceptions when they are truly
machine-specific. Document that `enableFor [ "desktop" "linux" ]` means
desktop **or** Linux, not Linux desktop; use explicit conjunction or an
appropriate role when both conditions are required.

**Done when:** adding a user or desktop needs few choices, overrides remain
obvious, and a Mac desktop cannot accidentally enable Linux desktop modules.

<a id="config-005"></a>

### [ ] CONFIG-005 Move Mac deployment facts out of shared modules — P2 · M

**Evidence:** [system/darwin.nix](system/darwin.nix) disables Nix management for
every Mac and derives the primary user alphabetically.
[The Homebrew module](system/modules/darwin/homebrew/homebrew.nix) hardcodes
Workbrew paths and completion workarounds. The README tells another Mac user
to edit that shared module.

Represent Nix ownership, primary user, and Homebrew/Workbrew mode in host data
or host settings. Keep the Workbrew workaround conditional on that deployment.
Move personal app selections to the host where appropriate.

**Done when:** the existing Mac retains its behavior, a normal Mac can be added
without editing shared implementation, and an explicit primary user must belong
to the host. Evaluate fixtures on Linux and test activation on the actual Mac.

## 3. Make recovery and unattended jobs trustworthy

<a id="ops-001"></a>

### [ ] OPS-001 Define backup retention, verification, and restore drills — P1 · M

**Evidence:** [system/timers/nelson.nix](system/timers/nelson.nix) defines three
Restic repositories and backup paths, but no explicit retention policy,
repository checks, restore drill, or failure notification. Only framework
enables these timers in the current host files.

Write down the recovery scope for each host: data, credentials, application
state, and anything deliberately excluded. Decide retention per destination,
schedule integrity checks, surface failures and stale snapshots, and practice
restoring files into a temporary directory. Document repository initialization
and credential recovery separately from the machine being backed up.

**Done when:** a restore drill has a recorded date and result, backup age is
visible, and each host has an explicit backup decision. Treat deletion/pruning
policy as a reviewed change, not an incidental optimization.

<a id="ops-002"></a>

### [ ] OPS-002 Spread backup work and inspect exclusions — P2 · M

**Evidence:** all three repositories start at `Mon..Fri 17:00`, scan the same
paths, and use maximum compression. [exclude.txt](home/programs/restic/exclude.txt)
contains a large set of development exclusions.

Measure backup duration, CPU, disk activity, and network volume. Stagger starts
or sequence jobs; evaluate compression against actual storage savings. Check
that exclusions do not remove valuable untracked source or local data. Consider
laptop sleep, battery, and unavailable networks, with bounded retries and
clear stale-backup reporting.

**Done when:** backups meet an agreed freshness target without competing for
the same resources unnecessarily, and representative excluded/included paths
are verified with a dry run and restore.

<a id="ops-003"></a>

### [ ] OPS-003 Make timer services independent of interactive state — P1 · M

**Evidence:** [mkSystemTimer](system/lib/mkSystemTimer.nix) names units only by
job name, so multiple users would collide. The database-client backup exits on
`git diff --quiet`, which misses untracked-only work, and obtains its commit
message from a network service. Shell backup aliases also hardcode framework's
repositories in [aliases.zsh](home/programs/zsh/aliases.zsh).

Include the user in unit and wrapper names. Set working directories, command
dependencies, timeouts, and appropriate retry/failure handling. Detect staged,
unstaged, and untracked changes deliberately. Use a local deterministic commit
message and retry a failed push even if there is no new diff. Generate backup
commands from the same repository definitions as the services. Document that
the books `rclone sync` mirrors deletions and is distinct from versioned backup.

**Done when:** two users can enable jobs without collisions; offline runs fail
clearly and recover; untracked-only changes and pending pushes are covered.

<a id="ops-004"></a>

### [ ] OPS-004 Document secrets and first-login provisioning — P1 · M

**Evidence:** timers expect an external Restic password, rclone configuration,
and SSH key. [system/nixos.nix](system/nixos.nix) creates accounts but does not
define a repository-wide first-login or credential provisioning process.

Create an inventory of required secret paths, owners, permissions, provisioning
steps, and recovery sources without recording secret values. Decide whether
manual provisioning is sufficient or encrypted declarative provisioning earns
its complexity. Keep plaintext credentials out of Git and Nix store inputs.
Add a check for accidental credential files that reports paths without printing
their contents.

**Done when:** a fresh machine can obtain login access and backup credentials
from documented steps, with no dependency on secrets available only on the
failed machine.

<a id="ops-005"></a>

### [ ] OPS-005 Review temis network access and service exposure — P1 · M

**Evidence:** [temis.nix](system/hosts/temis.nix) enables SSH and Docker while
explicitly disabling the firewall. This review did not inspect its real network
exposure, authorized keys, or effective SSH defaults.

Inventory required listeners, container port publishing, LAN access, and
Tailscale access. Define a minimal host firewall policy and explicit SSH access
policy. Verify recovery access before changing either. Review privileged group
membership per host instead of inheriting workstation groups everywhere.

**Done when:** allowed services are documented and tested from the intended
networks, administrative access is preserved, and unexpected listeners are
identified. Do not assume Tailscale alone defines the host's exposure.

<a id="ops-006"></a>

### [ ] OPS-006 Align rollback and garbage-collection policy — P1 · S

**Evidence:** [bin/autoclean](bin/autoclean) uses seven-day deletion while
[system/nixos.nix](system/nixos.nix) configures monthly collection with 31-day
retention. The README explains build and switch but has no recovery procedure.

Explain system rollback, standalone Home Manager rollback, failed activation,
boot recovery, and restoring the matching repository revision. Live symlinks
mean an old generation alone does not restore old application configuration.
Agree on retention across manual cleanup, automatic cleanup, boot entries, and
the Mac's separately managed Nix installation. Add a preview before cleanup.

**Done when:** a recovery walkthrough identifies both the generation and source
revision needed, and cleanup preserves the intended recovery window.

## 4. Improve daily development and reproducibility

<a id="dx-001"></a>

### [ ] DX-001 Remove network cloning from shell activation — P1 · M

**Evidence:** [zsh.nix](home/programs/zsh/zsh.nix) pins plugins but clones Oh My
Zsh from its current Git branch during activation. The runtime shell then
sources that mutable checkout.

Supply Oh My Zsh through a pinned package/source or the upstream Home Manager
integration. Keep custom plugins and themes explicit. Define how shell updates
happen so they cannot silently drift independently of the repository.

**Done when:** activation needs no shell-framework network fetch after the
closure is built, and rebuilding the same inputs selects the same framework.

<a id="dx-002"></a>

### [ ] DX-002 Measure and simplify shell startup — P2 · M

**Evidence:** [zshrc](home/programs/zsh/zshrc) scans the entire repository for
`*.init` files and shells out to `ls`/`sort` to load Zsh modules. Its word-split
loops are fragile with spaces in the checkout path.
[plugins.zsh](home/programs/zsh/plugins.zsh) also enables integrations
independently of the corresponding program flags.

Measure cold and warm interactive startup, then replace broad discovery with
an explicit ordered list or a manifest derived from enabled programs. Use
quoted paths and native shell globbing where appropriate. Ensure completions,
direnv, mise, fzf, and zoxide initialize once. Keep optional Spells optional.

**Done when:** a minimal home opens a usable shell without missing-command
errors; startup from a checkout containing spaces works; before/after timings
show whether the change helped. Set a latency target after taking the baseline.

<a id="dx-003"></a>

### [ ] DX-003 Make runtime ownership explicit — P2 · M

**Evidence:** Python and Ruby come from Nix, Node and Go modules supply mise
defaults, Rust uses rustup, and Neovim combines Nix language servers with Mason.
These are reasonable choices but their boundaries are not documented together.

Define which layer owns each runtime: machine tools, project versions, editor
servers, and global utilities. Document PATH precedence and project overrides.
Provide a small project-environment example for the languages used most often,
without forcing every project into one tool.

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

Track plugin versions and define bootstrap/update ownership. Check that every
enabled language server is supplied explicitly. Support launching Neovim outside
an interactive Zsh session. Make VS Code extension installation location-aware,
repeatable, and clear about whether extension versions are pinned or mutable.

**Done when:** a clean temporary home can start the editor, find its config,
and open representative projects; missing dependencies report actionable
errors. Test first launch separately from a mature local installation.

<a id="dx-005"></a>

### [ ] DX-005 Formalize live, generated, and app-owned files — P2 · M

**Evidence:** [mkSymlink](home/lib/mkHomeModule.nix) validates repository source
existence, but live targets still depend on the checkout remaining in place.
Claude has a custom direct-link activation; Herdr copies mods and allows apps
to write through some configuration links.

Document file ownership per app: live source, immutable generated file, copied
asset, or private runtime state. Separate stable preferences from machine-local
state where the application permits it. Check the live checkout before
activation and provide a procedure for moving it. Quote custom activation paths
consistently, including Claude's path. Keep app-written changes reviewable.

**Done when:** users can tell which edits require rebuilding or reloading, which
survive rollback, and which are overwritten. Activation tests cover existing
files, broken links, repeated runs, and paths with spaces without touching the
real home.

<a id="dx-006"></a>

### [ ] DX-006 Add a read-only diagnostic command and finish onboarding — P2 · M

**Evidence:** useful diagnostics are spread across the README and helpers. The
README promises automatic direnv loading, but no `.envrc` is tracked in this
checkout. [home/scripts.nix](home/scripts.nix) also assumes GNU `stat`/`date`
and particular generation directories.

Add a diagnostic helper that reports the selected outputs, Nix features,
checkout path, missing live targets, external prerequisites, backup freshness,
and the next useful command. Add the promised `.envrc` or correct the docs.
Make generation-diff helpers handle no generations, cancellation, alternate
profile paths, and platform-specific dependencies. Keep diagnostics free of
secret contents and automatic repairs.

**Done when:** a fresh clone has a tested setup/build path for NixOS, standalone
Home Manager, and the managed Mac; diagnosis works without a successful switch.

## 5. Improve CI and maintenance efficiency

<a id="ci-001"></a>

### [ ] CI-001 Add fast checks for the files that actually change — P2 · M

**Evidence:** [flake.nix](flake.nix) lints Nix, but the repository also contains
Xonsh, Bash, Zsh, Lua, JSON/JSONC, YAML, and JavaScript. The Herdr
[profile-picture test](home/programs/herdr-app/mods/profile-pictures/remote.test.mjs)
is not invoked by the declared flake checks or workflow.

Add syntax checks and focused tests for maintained scripts and configs. Use
format-aware parsers, particularly for JSON with comments. Run the existing
JavaScript test in CI after confirming its dependencies. Distinguish locally
maintained code from imported assets so formatting does not create vendor noise.
Offer an optional local check hook that runs the same checks as CI.

**Done when:** representative script/config mistakes fail before expensive
builds; dependencies are pinned through the dev shell/check derivations; a
documentation-only edit has an appropriately cheap validation path.

<a id="ci-002"></a>

### [ ] CI-002 Measure build costs and make cache retention resilient — P2 · M

**Evidence:** [CI](.github/workflows/ci.yml) retains selected slow builds only
after `nix flake check` succeeds and hardcodes framework's Vicinae and Herdr
attributes. Its comments describe long source builds and a large closure;
those figures were not remeasured here.

Record evaluation time, cold/warm build time, cache hits, closure size, and
runner disk use. Retain successfully built expensive outputs even when a later
unrelated check fails, using supported cache-action behavior. Define cache
targets independently of a particular host where practical. Consider a shared
binary cache only if measurements justify its cost and maintenance.

**Done when:** repeat runs demonstrably reuse the expensive outputs, cache
targets survive host renames or disabled programs, and failures preserve useful
diagnostics. Do not optimize by silently dropping configuration coverage.

<a id="ci-003"></a>

### [ ] CI-003 Cover the gap between evaluation and activation — P2 · L

**Evidence:** current checks build Home Manager activation packages but only
evaluate system toplevels. Neither step exercises live links, timer execution,
desktop behavior, or Workbrew activation.

Add a scheduled/manual native system build where affordable. Use a small NixOS
VM test for critical service behavior and temporary-home tests for activation
scripts. Maintain a short manual Mac smoke test for shell startup, app paths,
Homebrew, and rollback; a generic CI Mac cannot reproduce the managed laptop.

**Done when:** reports distinguish evaluated, built, activated, and manually
verified behavior. Keep expensive coverage separate from fast feedback.

<a id="ci-004"></a>

### [ ] CI-004 Track external patches, assets, and workflow dependencies — P2 · M

**Evidence:** [config/overlays.nix](config/overlays.nix) carries temporary Herdr
and GNOME fixes, while Herdr mods include substantial copied upstream code and
icons. CI uses version tags and a moving `main` reference for external actions.

Record source revision, license, local changes, update procedure, and removal
condition for each imported component or patch. Pin workflow actions to reviewed
revisions and maintain a deliberate update process. Review whether added flake
inputs still earn their cost and whether upstream packages can replace local
overrides. Preserve lazy platform behavior in shared overlays.

**Done when:** an input upgrade includes a short patch/vendor review, stale
workarounds are removed when verified unnecessary, and imported assets retain
their provenance and licenses.

<a id="ci-005"></a>

### [ ] CI-005 Separate package reconciliation from surprise upgrades — P2 · M

**Evidence:** [Homebrew activation](system/modules/darwin/homebrew/homebrew.nix)
sets `autoUpdate`, `upgrade`, and `cleanup = "uninstall"`. Thus the same Nix
revision can trigger different external package changes on different days.
The module also documents a possible Workbrew/sudo conflict, not a verified
successful activation path.

Choose an explicit policy for external package upgrades and cleanup. Make it
clear which applications Nix owns, which Workbrew owns, and which update
themselves, including Herdr on macOS. Preview removals where possible. Verify
the supported Workbrew activation path on the managed Mac before relying on it.

**Done when:** a routine configuration switch has a predictable scope and the
docs distinguish declarative selection from version reproducibility.

## 6. Optional extensions after the foundations

<a id="platform-001"></a>

### [ ] PLATFORM-001 Generate an inventory from evaluated configuration — P3 · M

Expose a human-readable and JSON view of hosts, roles, users, enabled programs,
and available outputs. Use it for diagnostics and script target selection
instead of separately parsing Nix source. Explain inclusion through explicit
role/profile metadata where practical; do not build a general provenance engine.

**Done when:** the inventory agrees with evaluated outputs and removes at least
one duplicated source of truth.

<a id="platform-002"></a>

### [ ] PLATFORM-002 Make reinstalling and remote maintenance repeatable — P3 · L

Document disk layout, boot mode, encryption recovery, first login, and restoring
data for each NixOS machine. Decide whether declarative disk provisioning is
worth introducing. Add remote build/deployment support only if temis maintenance
needs it, with explicit target selection, preview, connectivity checks, and a
rollback route. Keep activation separately authorized.

**Done when:** a disposable VM or spare machine can be installed from the
instructions, and remote operations cannot accidentally select the local host.

<a id="platform-003"></a>

### [ ] PLATFORM-003 Audit desktop services and inactive configurations — P3 · M

Measure idle memory, startup services, GNOME extension behavior, and app launch
times before tuning. Review disabled editors, window managers, modules, and
large copied assets for continued usefulness. Keep intentional alternatives;
archive abandoned experiments with enough history to recover them.

**Done when:** removals have a clear maintenance or measured resource benefit,
and desktop changes have a short regression checklist covering shortcuts,
theme changes, display behavior, audio, suspend, and notifications.

## Suggested delivery order

1. **Trust the tooling:** [CLI-001](#cli-001), [CLI-002](#cli-002), [CLI-004](#cli-004),
   [CLI-005](#cli-005), [CONFIG-001](#config-001), and focused tests from [CONFIG-002](#config-002).
   These prevent misleading success and accidental changes while improving the
   tools used for every later step.
2. **Prove recovery:** [OPS-001](#ops-001), [OPS-003](#ops-003), [OPS-004](#ops-004),
   [OPS-005](#ops-005), [OPS-006](#ops-006), [DX-001](#dx-001). Record a restore drill
   before changing backup retention or reducing recovery generations.
3. **Improve daily use:** [CLI-003](#cli-003), [CONFIG-003](#config-003), [CONFIG-004](#config-004),
   [CONFIG-005](#config-005), [DX-002](#dx-002), [DX-003](#dx-003),
   [DX-004](#dx-004), [DX-005](#dx-005), [DX-006](#dx-006). Measure closure size and
   shell startup before simplifying them.
4. **Shorten feedback:** [OPS-002](#ops-002), [CI-001](#ci-001), [CI-002](#ci-002),
   [CI-003](#ci-003), [CI-004](#ci-004), [CI-005](#ci-005). Add runtime coverage and
   improve caching using measured costs.
5. **Extend only where useful:** [PLATFORM-001](#platform-001), [PLATFORM-002](#platform-002), [PLATFORM-003](#platform-003),
   after the earlier work demonstrates which missing capabilities would save time.

Implement each item as a reviewable change with its relevant validation. Follow
the repository's Nix lint/evaluation/build rules for code changes, update the
README when behavior changes, and preserve approval requirements for switching,
cleanup, updates, commits, and pushes. This roadmap itself authorizes none of
those operations.
