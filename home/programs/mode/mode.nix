{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    (callPackage ./package.nix { })
  ];
}
