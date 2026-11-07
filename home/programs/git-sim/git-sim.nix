{
  pkgs,
  ...
}:
{
  # git-sim 0.4.0 built here; nixpkgs still ships 0.3.5. See package.nix.
  home.packages = [
    (pkgs.callPackage ./package.nix { })
  ];
}
