{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ── Packages & Homebrew ──────────────────────────────────────────────
  dotfiles.modules.homebrew.enable = true;
}
