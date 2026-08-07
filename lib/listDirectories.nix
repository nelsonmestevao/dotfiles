# Names of the sub-directories of `dir`.
#
# Module trees here are laid out as `<dir>/<name>/<name>.nix`, so callers only
# ever want directory names. Filtering on the entry type means a stray file —
# a README, a .gitkeep, an editor backup — can't become a broken import.
{ lib }:
dir: lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir))
