{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    spotify
  ];
}
