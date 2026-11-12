# The packages this repo builds or changes itself, as flake outputs, so each
# one can be built alone: `nix build .#git-sim`.
#
# To add one, put a `package.nix` in its program's folder. Nothing else: it is
# found here and named after that folder.
#
# A package says where it runs with `meta.platforms`, and a system only gets
# the ones that run on it. One that doesn't say gets its builder's default.
{ nixpkgs, overlays }:
system:
let
  inherit (nixpkgs) lib;
  # Joins two sets of packages, and stops when both have one of the same name.
  # Otherwise one would quietly replace the other.
  inherit (lib.attrsets) unionOfDisjoint;

  # The package set the configurations use, so an output is the very
  # derivation a home installs.
  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };

  # A program's own package: every package.nix under home/programs.
  packageFiles = lib.filter (file: baseNameOf file == "package.nix") (
    lib.filesystem.listFilesRecursive ../home/programs
  );
  packageIn = file: { ${baseNameOf (dirOf file)} = pkgs.callPackage file { }; };
  ownPackages = lib.foldl' unionOfDisjoint { } (map packageIn packageFiles);

  # A package that config/overlays.nix patches or forks. These have no file to
  # find, so they are named here: one patched there is added here too.
  overriddenPackages = {
    inherit (pkgs) herdr-app;
    inherit (pkgs.gnomeExtensions) wiggle;
  };

  runsHere = lib.meta.availableOn pkgs.stdenv.hostPlatform;
in
lib.filterAttrs (_: runsHere) (unionOfDisjoint ownPackages overriddenPackages)
