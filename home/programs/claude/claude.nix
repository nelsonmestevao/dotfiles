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
    claude-code
  ];

  # ── Symlinked Config Files ───────────────────────────────────────────
  home.file.".claude/skills" = mkSymlink "skills";
}
