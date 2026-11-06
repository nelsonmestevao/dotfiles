{
  pkgs,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    discord
  ];
}
