{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
  ];

  # ── Programs ──────────────────────────────────────────────────────────
  programs.firefox.enable = true;
}
