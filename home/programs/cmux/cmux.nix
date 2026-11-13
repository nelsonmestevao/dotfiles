{
  pkgs,
  mkSymlink,
  ...
}:
{
  platforms = [ "darwin" ];

  # cmux 0.65, built here while nixpkgs still has 0.64. See package.nix.
  home.packages = [
    (pkgs.callPackage ./package.nix { })
  ];

  # Terminal settings come from ghostty's config; cmux.json holds cmux-owned
  # settings such as keyboard shortcuts.
  xdg.configFile."cmux/cmux.json" = mkSymlink "cmux.json";
}
