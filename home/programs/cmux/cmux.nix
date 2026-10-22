{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # ── Packages ──────────────────────────────────────────────────────────
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin (
    with pkgs;
    [
      unstable.cmux
    ]
  );

  # ── Symlinked Config Files ───────────────────────────────────────────
  # Terminal settings come from ghostty's config; cmux.json holds cmux-owned
  # settings such as keyboard shortcuts.
  xdg.configFile = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    "cmux/cmux.json" = mkSymlink "cmux.json";
  };
}
