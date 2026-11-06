{
  pkgs,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    pkgs.unstable.beeper
  ];
}
