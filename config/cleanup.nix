# ── Cleanup ────────────────────────────────────────────────────────────────
#
# What `nh clean all` keeps, for NixOS's monthly cleanup (system/nixos.nix) and
# for bin/autoclean, so the two can't differ: the last 31 days, and at least
# the newest 3 generations of each profile, however old.
#
# `--no-gcroots` leaves the `result` links and direnv dev shells in your
# project folders alone. Without it, nh would delete the ones older than 31
# days, and an old project would download its dev shell again.
[
  "--keep-since"
  "31d"
  "--keep"
  "3"
  "--no-gcroots"
]
