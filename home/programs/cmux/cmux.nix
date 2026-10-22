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
  # home.file.".config/cmux" = mkSymlink "config";
  # xdg.configFile."cmux/config" = mkSymlink "config";
  # xdg.configFile."cmux/config.toml" = mkSymlink "config.toml";
}
