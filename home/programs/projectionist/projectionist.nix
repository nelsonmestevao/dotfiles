{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    (callPackage ./package.nix { })
  ];

  home.shellAliases.pj = "projectionist";
}
