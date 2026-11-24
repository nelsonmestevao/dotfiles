{
  lib,
  pkgs,
  ...
}:
{
  # On macOS, Herdr.app installs herdr-core itself. herd works on every
  # machine with Herdr: it needs only hc, or herdr-app where the window runs.
  home.packages =
    lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) (
      with pkgs;
      [
        herdr-core
      ]
    )
    ++ [
      (pkgs.callPackage ./herd/package.nix { })
    ];
}
