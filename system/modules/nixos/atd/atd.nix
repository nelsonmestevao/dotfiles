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

  # ── Services ──────────────────────────────────────────────────────────
  services.atd.enable = true;
}
