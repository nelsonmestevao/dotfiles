{
  lib,
  pkgs,
  ...
}:
{
  # On macOS, Herdr.app installs herdr-core itself.
  home.packages = lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.herdr-core ];
}
