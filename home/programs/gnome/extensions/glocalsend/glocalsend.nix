{ pkgs, ... }:
{
  package = pkgs.callPackage ./package.nix { };
}
