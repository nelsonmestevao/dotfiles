{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    pkgs.unstable.opencode
    pkgs.unstable.opencode-claude-auth
  ];
}
