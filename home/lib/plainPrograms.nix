# One module for each program in home/programs/plain.nix, made with
# mkHomeModule like a program folder: it gets dotfiles.programs.<name>.enable,
# and turning it on installs the package.
#
# `pkgs` here only gives the names. Each module takes its package from the
# module system's own `pkgs`, which has the overlays.
{ lib, pkgs }:
let
  programsIn = import ../programs/plain.nix;
  mkHomeModule = import ./mkHomeModule.nix;

  plainProgram =
    name:
    mkHomeModule {
      inherit name;
      file = "home/programs/plain.nix";
    } ({ pkgs, ... }: { home.packages = [ (programsIn pkgs).${name} ]; });
in
map plainProgram (lib.attrNames (programsIn pkgs))
