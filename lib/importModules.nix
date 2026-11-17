# One module per sub-directory of `folder`, a path from the repo root like
# "home/programs".
#
# Module trees here are laid out as `<folder>/<name>/<name>.nix`. Each one is
# imported and handed to `wrap { name; file; }`, which turns it into a module
# (see mkHomeModule, mkSystemModule). That `file` is the module's path from the
# repo root, like "home/programs/zsh/zsh.nix", so a wrapper can name it in
# messages without knowing the layout. Only sub-directories count, so a stray
# file — a README, a .gitkeep, an editor backup — can't become a broken import.
# A folder whose name starts with `_` is left out, for drafts and notes.
{ lib }:
wrap: folder:
let
  dir = ../. + "/${folder}";
  isModule = name: type: type == "directory" && !lib.hasPrefix "_" name;
in
lib.mapAttrsToList (
  name: _:
  let
    file = "${folder}/${name}/${name}.nix";
    path = ../. + "/${file}";
  in
  lib.throwIfNot (builtins.pathExists path)
    "${folder}/${name} has no ${name}.nix. Add it (and `git add` it: the flake only sees tracked files), or start the folder's name with _ to leave it out."
    (wrap { inherit name file; } (import path))
) (lib.filterAttrs isModule (builtins.readDir dir))
