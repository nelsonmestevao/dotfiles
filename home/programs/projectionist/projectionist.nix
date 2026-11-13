{
  pkgs,
  ...
}:
{
  home.packages = [ (pkgs.callPackage ./package.nix { }) ];

  home.shellAliases.pj = "projectionist";
}
