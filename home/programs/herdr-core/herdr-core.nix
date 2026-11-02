{
  config,
  lib,
  pkgs,
  mkSymlink,
  ...
}:
{
  # On macOS, Herdr.app installs herdr-core itself.
  home.packages = lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) (
    with pkgs;
    [
      herdr-core
    ]
  );
}
