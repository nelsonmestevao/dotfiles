{
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  # `orca-app`, not `orca`, which is GNOME's screen reader (see the overlay).
  home.packages = with pkgs; [
    orca-app
  ];

  # ── Terminal Themes ──────────────────────────────────────────────────
  # Orca keeps its settings in a SQLite profile database, so there is no
  # config file to manage. Its "Import from Warp" button scans this folder;
  # import the theme there once, then pick it as the dark terminal theme.
  xdg.dataFile."warp-terminal/themes/orca-dark.yaml" = mkSymlink "themes/orca-dark.yaml";
}
