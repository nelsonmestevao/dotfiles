---
name: hc
description: >-
  Run work in the background with hc (herdr-core): start Claude, Codex or pi agents in
  terminals that stay alive, run dev servers and long test suites, wait on them, read
  their output, and run commands or edit files on other machines. Use it when
  $HC_TERMINAL_ID is set and work should go on in the background, or when the user says
  "hc", "herdr", "in the background", "delegate", "spawn an agent" or "hand this off".
  Use it instead of Bash run_in_background and background Agent subagents, so the user
  can watch and attach to the work.
allowed-tools: Bash(hc:*)
---

# hc

This stub loads the manual from the installed `hc`, so it matches its version.
If the manual is missing below, run `hc --skill` and follow what it prints.

In Claude Code, the Bash tool stops a command after 120 seconds by default, and
`hc wait` checks in after 180. Pass `--timeout 100` to `hc wait`, or give the
Bash call a longer timeout.

!`hc --skill`
