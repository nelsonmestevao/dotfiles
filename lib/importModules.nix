# One module per sub-directory of `dir`.
#
# Module trees here are laid out as `<dir>/<name>/<name>.nix`. Each one is
# imported and handed to `wrap name`, which turns it into a module (see
# mkHomeModule, mkSystemModule). Only sub-directories count, so a stray file —
# a README, a .gitkeep, an editor backup — can't become a broken import.
{ lib }:
wrap: dir:
lib.mapAttrsToList (name: _: wrap name (import (dir + "/${name}/${name}.nix"))) (
  lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)
)
