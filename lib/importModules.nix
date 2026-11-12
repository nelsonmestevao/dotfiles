# One module per sub-directory of `folder`, a path from the repo root like
# "home/programs".
#
# Module trees here are laid out as `<folder>/<name>/<name>.nix`. Each one is
# imported and handed to `wrap { name; folder; }`, which turns it into a module
# (see mkHomeModule, mkSystemModule). That `folder` is the module's own, like
# "home/programs/zsh", so a wrapper can name the module's files in messages
# without knowing the layout. Only sub-directories count, so a stray file — a
# README, a .gitkeep, an editor backup — can't become a broken import.
{ lib }:
wrap: folder:
let
  dir = ../. + "/${folder}";
in
lib.mapAttrsToList (
  name: _:
  wrap {
    inherit name;
    folder = "${folder}/${name}";
  } (import (dir + "/${name}/${name}.nix"))
) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir))
