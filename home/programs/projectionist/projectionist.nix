{
  pkgs,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    (callPackage ./package.nix { })
  ];

  # ── Shell Integration ────────────────────────────────────────────────
  home.shellAliases.pj = "projectionist";
}
