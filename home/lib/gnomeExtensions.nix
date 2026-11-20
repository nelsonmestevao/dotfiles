# Every GNOME extension as a module: one for each folder in
# home/programs/gnome/extensions, and one for each name in its plain.nix. Both
# kinds are made with mkGnomeExtensionModule, so each one gets
# dotfiles.programs.gnome.extensions.<name>.enable, and turning it on installs
# the package and enables the extension.
#
# `pkgs` here only gives the names in plain.nix. Each module takes its package
# from the module system's own `pkgs`, which has the overlays.
{ lib, pkgs }:
let
  folder = "home/programs/gnome/extensions";
  importModules = import ../../lib/importModules.nix { inherit lib; };
  mkGnomeExtensionModule = import ./mkGnomeExtensionModule.nix;
  plainIn = import ../programs/gnome/extensions/plain.nix;

  inFolders = lib.listToAttrs (
    importModules (
      extension: body: lib.nameValuePair extension.name (mkGnomeExtensionModule extension body)
    ) folder
  );

  inPlain = lib.mapAttrs (
    name: _:
    mkGnomeExtensionModule {
      inherit name;
      file = "${folder}/plain.nix";
    } ({ pkgs, ... }: { package = (plainIn pkgs).${name}; })
  ) (plainIn pkgs);
in
# Listed by name, whichever kind each one is: GNOME gets its extensions in
# this order. An extension that is in both places stops the build.
lib.attrValues (lib.attrsets.unionOfDisjoint inFolders inPlain)
